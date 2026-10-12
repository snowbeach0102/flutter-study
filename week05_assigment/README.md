# 5주차 과제 — 상태 기능과 작업 컨텍스트

- **프로젝트 명**: 나의 할 일(Todo) 상태 관리 대시보드
- **작업 환경**: Flutter (Material 3), Windows Command Prompt (CLI)
- **제출 저장소**: 본인 5주차 과제 GitHub 저장소

---

## 1. 제출 개요 및 핵심 4대 질문 답변

과제 요구사항에 따른 4대 질문에 대한 명확한 아키텍처 답변입니다.

### Q1. 누가 상태를 소유하는가? (State Ownership)

- **소유자**: `_TodoStatePageState` (`State<TodoStatePage>`)
- **이유**: 할 일 목록 원본 데이터(`_todoList`)의 생성, 유지, 변경(`setState`) 권한을 메인 페이지의 State 객체가 단독 소유합니다. 하위 할 일 행 위젯(`_buildTodoRow`)은 상태를 직접 소유하거나 변이시키지 않고, 전달받은 콜백 함수(`onToggle`)를 실행하여 소유자에게 상태 변경을 요청(State Lifting / 단방향 데이터 흐름)합니다.

### Q2. AI에게 어떤 자료를 왜 제공했는가? (Context Provisioning)

- **제공 자료**:
  1. 5주차 강의 슬라이드 캡처 ("버튼 한 번에 달라지는 두 곳: 첫 할 일을 완료하면 카드 표시와 남은 할 일 수가 함께 바뀝니다")
  2. 기술적 제약 및 요구사항: 행 전체 터치 영역(`InkWell`) 확대, 단일 진실 공급원(SSOT) 준수, 파생 상태 계산 게터 사용, 외부 라이브러리 배제
- **이유**: 강의에서 요구하는 핵심 철학(단일 상태 변경으로 2개 이상의 UI가 동기화되는 구조)을 정확하게 충족하고, 임의의 복잡한 패키지(Provider, Riverpod 등) 없이 Flutter 순수 `setState` 메커니즘을 정확히 구현하기 위함입니다.

### Q3. 실행 증거가 어느 AC를 확인하는가? (AC Traceability)

- **AC1 (초기값 일치)**: 최초 로드 시 남은 할 일 2개 표시 및 2개 항목 모두 빈 원(미완료) 렌더링 확인
- **AC2 (상태/화면 동시 변경)**: 첫 번째 항목 클릭 시 '남은 할 일'이 즉시 1로 감소하고, 해당 카드가 체크 아이콘/민트 배경/'취소' 버튼으로 동시 변경 확인
- **AC3 (역동작 원복)**: 완료된 첫 번째 항목 재클릭 시 '남은 할 일'이 다시 2로 증가하고, 카드가 초기 미완료 상태로 완벽히 원복 확인
- **AC4 (중복 저장 방지)**: `_remainingCount`를 별도 변수로 저장하지 않고 게터로 실시간 계산함을 코드 레벨에서 확인

### Q4. 다음 수정에 무엇을 다시 읽어야 하는가? (Context Maintenance)

- **필수 참조 문서**:
  1. `CONTEXT_PACKET.md`: 프로젝트의 목표, 인수 조건(AC), 기술적 제약 조건 확인
  2. `PROMPT_COMPARISON.md`: AI 프롬프트 작성 시의 명확성과 결과 비교 기준 확인
  3. `lib/main.dart`: 상태 소유 위치(`_TodoStatePageState`) 및 `_toggleTodoStatus` 이벤트 핸들러 확인

---

## 2. 상태 계약 (State Contract)

| 구분                 | 상태 명칭         | 자료형           | 상태 소유 위치        | 역할 및 보장 조건 (불변식)                                                                                          |
| :------------------- | :---------------- | :--------------- | :-------------------- | :------------------------------------------------------------------------------------------------------------------ |
| **원본 상태 (SSOT)** | `_todoList`       | `List<TodoItem>` | `_TodoStatePageState` | 유일한 원본 진실 공급원. 각 항목의 `title`과 `isCompleted` 불리언 값을 유지함.                                      |
| **파생/계산값**      | `_remainingCount` | `int (Getter)`   | `_TodoStatePageState` | `_todoList.where((item) => !item.isCompleted).length`로 실시간 계산. **별도 변수로 중복 저장하지 않음 (AC4 달성)**. |

---

## 3. 이벤트 → 상태 → UI 상태 흐름도

```text
[사용자 입력 이벤트 (Action)]
사용자가 목록 카드 행 전체 또는 우측 버튼 탭
       │
       ▼
[이벤트 디스패치 (Event Dispatch)]
InkWell.onTap -> onToggle() 호출 -> _toggleTodoStatus(index) 실행
       │
       ▼
[상태 변경 (State Mutation)]
setState(() {
  _todoList[index].isCompleted = !_todoList[index].isCompleted;
});
// Flutter 프레임워크에 State 객체 dirty 플래그 마킹
       │
       ▼
[위젯 트리 리빌드 (Rebuild)]
build() 메서드 재실행
       ├── [달라지는 곳 1]: _remainingCount 재계산 -> "남은 할 일 X" 텍스트 갱신
       └── [달라지는 곳 2]: _buildTodoRow 조건부 렌더링 -> 배경색, 아이콘, 텍스트(완료/취소) 갱신
```
