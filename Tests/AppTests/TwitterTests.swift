@testable import App

import XCTVapor
import SemanticVersion


class TwitterTests: AppTestCase {
    
    func test_buildPost() throws {
        XCTAssertEqual(
            Twitter.firehostPost(
                repositoryName: "owner",
                url: "http://localhost:8080/owner/SuperAwesomePackage",
                version: .init(2, 6, 4),
                summary: "This is a test package"),
            """
            owner just released version 2.6.4 – This is a test package

            http://localhost:8080/owner/SuperAwesomePackage
            """
        )

        // no summary
        XCTAssertEqual(
            Twitter.firehostPost(
                repositoryName: "owner",
                url: "http://localhost:8080/owner/SuperAwesomePackage",
                version: .init(2, 6, 4),
                summary: nil),
            """
            owner just released version 2.6.4

            http://localhost:8080/owner/SuperAwesomePackage
            """
        )
    }

    func test_postToFirehose() throws {
        // setup
        let pkg = Package(url: "1".asGithubUrl.url)
        try pkg.save(on: app.db).wait()
        try Repository(package: pkg,
                       summary: "This is a test package",
                       name: "owner").save(on: app.db).wait()
        let version = try Version(package: pkg, packageName: "MyPackage", reference: .tag(1, 2, 3))
        try version.save(on: app.db).wait()

        // MUT
        let res = try Twitter.firehostPost(db: app.db, for: version).wait()

        // validate
        XCTAssertEqual(res, """
        owner just released version 1.2.3 – This is a test package

        https://github.com/foo/1
        """)
    }

    func test_onlyReleaseAndPreRelease() throws {
        // ensure we only tweet about releases and pre-releases
        // setup
        let pkg = Package(url: "1".asGithubUrl.url)
        try pkg.save(on: app.db).wait()
        try Repository(package: pkg,
                       summary: "This is a test package",
                       name: "owner").save(on: app.db).wait()
        let v1 = try Version(package: pkg, packageName: "MyPackage", reference: .tag(1, 2, 3))
        try v1.save(on: app.db).wait()
        let v2 = try Version(package: pkg, packageName: "MyPackage", reference: .tag(2, 0, 0, "b1"))
        try v2.save(on: app.db).wait()
        let v3 = try Version(package: pkg, packageName: "MyPackage", reference: .branch("main"))
        try v3.save(on: app.db).wait()
        Current.twitterCredentials = {
            .init(apiKey: ("key", "secret"), accessToken: ("key", "secret"))
        }
        var posted = 0
        Current.twitterPostTweet = { _, _ in
            posted += 1
            return self.app.eventLoopGroup.future()
        }

        // MUT
        try onNewVersions(client: app.client, transaction: app.db, versions: [v1, v2, v3]).wait()

        // validate
        XCTAssertEqual(posted, 2)
    }
}
