// Copyright 2020-2021 Dave Verwer, Sven A. Schmidt, and other contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FluentKit


struct Joined4<M: Model, R1: Model, R2: Model, R3: Model>: Joiner {
    private(set) var model: M
}


extension Joined4 {
    /// Query method that joins R1, R2 and R3 on M via the given join filters.
    /// - Returns: a `JoinedQueryBuilder<Self>`
    static func query<V1: Codable, V2: Codable, V3: Codable, L1: Schema, L2: Schema, L3: Schema>(
        on database: Database,
        join joinFilter1: JoinFilter<R1, L1, V1>,
        method method1: DatabaseQuery.Join.Method = .inner,
        join joinFilter2: JoinFilter<R2, L2, V2>,
        method method2: DatabaseQuery.Join.Method = .inner,
        join joinFilter3: JoinFilter<R3, L3, V3>,
        method method3: DatabaseQuery.Join.Method = .inner) -> JoinedQueryBuilder<Joined4> {
            .init(
                queryBuilder: M.query(on: database)
                    .join(R1.self, on: joinFilter1, method: method1)
                    .join(R2.self, on: joinFilter2, method: method2)
                    .join(R3.self, on: joinFilter3, method: method3)
            )
    }

    var relation1: R1? { try? model.joined(R1.self) }
    var relation2: R2? { try? model.joined(R2.self) }
    var relation3: R3? { try? model.joined(R3.self) }
}