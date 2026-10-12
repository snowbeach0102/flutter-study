5주차 과제 — 상태 기능과 작업 컨텍스트프로젝트 명: 나의 할 일(Todo) 상태 관리 대시보드작업 환경: Flutter (Material 3), Windows Command Prompt (CLI)제출 저장소: 본인 5주차 과제 GitHub 저장소1. 제출 개요 및 핵심 4대 질문 답변과제 요구사항에 따른 4대 질문에 대한 아키텍처 답변입니다.Q1. 누가 상태를 소유하는가? (State Ownership)소유자: \_TodoStatePageState (State<TodoStatePage>)이유: 할 일 목록 원본 데이터(\_todoList)의 생성, 유지, 변경(setState) 권한을 메인 페이지의 State 객체가 단독 소유합니다. 하위 할 일 행 위젯(\_buildTodoRow)은 상태를 직접 소유하거나 변이시키지 않고, 전달받은 콜백 함수(onToggle)를 실행하여 소유자에게 상태 변경을 요청(State Lifting / 단방향 데이터 흐름)합니다.Q2. AI에게 어떤 자료를 왜 제공했는가? (Context Provisioning)제공 자료:5주차 강의 슬라이드 캡처 ("버튼 한 번에 달라지는 두 곳: 첫 할 일을 완료하면 카드 표시와 남은 할 일 수가 함께 바뀝니다").기술적 제약 및 요구사항: 행 전체 터치 영역(InkWell) 확대, 단일 진실 공급원(SSOT) 준수, 파생 상태 계산 분리(중복 변수 생성 금지), flutter analyze 린트 준수.제공 이유:AI가 불필요하게 remainingCount를 별도 원본 변수로 두거나 외부 상태 관리 라이브러리(Provider, Riverpod 등)를 추가하여 과도한 설계를 하는 것을 방지하기 위함.강의 슬라이드의 UI 디자인(네이비 외곽선, 민트 하이라이트)과 Flutter 표준 setState의 동작 메커니즘을 1:1로 일치시키기 위해 제공함.Q3. 실행 증거가 어느 AC를 확인하는가? (Evidence Mapping)초기 화면 증거 (image-ac1.png): AC1 (초기 리스트 2개 미완료, 남은 할 일 수 2, 미완료 원형 아이콘 일치 확인)변경 화면 증거 (image-ac2.png): AC2 (첫 번째 카드 탭 1회에 남은 할 일 2 -> 1 변경 및 해당 카드 체크/민트 배경/취소 배지로 동시 갱신 확인)원복 화면 증거 (image-ac3.png): AC3 (동일 카드를 다시 탭했을 때 남은 할 일 1 -> 2 복귀 및 카드 상태 원복 확인)코드 검증: AC4 (\_remainingCount가 별도 필드가 아닌 Getter 계산값으로 선언되어 중복 저장이 없음을 확인)분석 증거 (image-analyze.png): AC7 (flutter analyze 경고/오류 0건 통과 확인)Q4. 다음 수정에 무엇을 다시 읽어야 하는가? (Next Iteration Context)CONTEXT_PACKET.md: 상태 계약 및 인수 조건(AC1~AC7) 명세 확인.lib/main.dart 상단 구조 주석: \_todoList와 \_remainingCount의 관계, \_toggleTodoStatus 메서드의 동기화 메커니즘.2. 상태 계약 (State Contract): 원본 상태 vs 계산값구분변수/프로퍼티 명타입관리 방식역할 및 특징원본 상태 (Source of Truth)\_todoListList<TodoItem>\_TodoStatePageState 내부 private 필드각 할 일 항목의 제목(title)과 완료 여부(isCompleted)를 저장하는 유일한 상태 원본.계산값 (Derived State)\_remainingCountint (Getter)\_todoList.where((i) => !i.isCompleted).length별도의 변수로 중복 저장하지 않고, build() 재실행 시마다 실시간 계산되어 상태 불일치를 원천 방지함.3. 이벤트 → 상태 → UI 상태 흐름도 (State Flow Diagram)[1. User Event]
사용자가 첫 번째 할 일 카드를 탭 (InkWell onTap)
│
▼
[2. Event Handler]
\_toggleTodoStatus(index: 0) 호출
│
▼
[3. State Mutation inside setState()]
\_todoList[0].isCompleted = !\_todoList[0].isCompleted; (false -> true)
Flutter 프레임워크에 State 'dirty' 마킹 통보
│
▼
[4. Rebuild & Derived Calculation]
TodoStatePage.build() 재실행
├── \_remainingCount Getter 재평가: 미완료 항목 1개로 계산 (2 -> 1)
└── List.generate() 순회하며 카드 위젯 트리 재빌드
│
▼
[5. UI Synchronization ("달라지는 두 곳")]
├── [UI 영역 1] 상단 "남은 할 일 1" 카운터 텍스트 즉시 갱신 (AC2)
└── [UI 영역 2] 첫 번째 카드: 배경(민트색), 아이콘(체크), 배지('취소') 동시 갱신 (AC2) 4. 프로젝트 컨텍스트 지도 (Context Map)week05_assigment/
├── CONTEXT_PACKET.md # 상태 목표, 현재 코드, 기술 제약, 인수 조건 명세
├── PROMPT_COMPARISON.md # 동일 요구사항에 대한 프롬프트 A/B 관찰 비교서
├── README.md # 본 문서 (상태 소유권, 상태 계약, 다이어그램, 총괄 검증)
└── lib/
└── main.dart # 상태 기능 구현 단일 소스코드
├── TodoItem (데이터 모델)
├── StateManagementLabApp (루트 StatelessWidget)
├── TodoStatePage (StatefulWidget)
└── \_TodoStatePageState (상태 소유자, setState 관리, Getter 계산) 5. 인수 조건(AC) 및 실행 증거 검증[x] AC1 (초기값과 첫 화면 일치): \_todoList 2개 미완료, 남은 할 일 2, 카드 2개 빈 원 정상 표시.[x] AC2 (입력 한 번에 상태와 화면 동시 변경): 첫 번째 카드 탭 1회로 남은 할 일 1 및 카드 체크 상태 동시 반영.[x] AC3 (역동작으로 값과 화면 원복): 완료된 첫 번째 카드 재탭 시 남은 할 일 2로 복구 및 카드 미완료 원복.[x] AC4 (표시값 별도 원본 중복 저장 금지): 남은 할 일 개수는 get \_remainingCount 계산 프로퍼티로 구현.[x] AC5 (작업 맥락 일치): 실제 프로젝트 파일(lib/main.dart) 및 위젯 구조와 컨텍스트 문서가 일치함.[x] AC6 (프롬프트 A/B 비교 관찰): PROMPT_COMPARISON.md 작성 및 비교 분석 완료.[x] AC7 (문서·코드·분석 일치): 모든 산출물이 단일 상태 기능(TodoItem.isCompleted)을 가리킴.6. 정적 분석 (flutter analyze) 및 Git Commit(1) flutter analyze 실행 결과Analyzing week05_assigment...
No issues found! (ran in 1.3s)
(2) Git Commit 정보Commit ID: (터미널의 git rev-parse --short HEAD 결과 기입)Branch: main
