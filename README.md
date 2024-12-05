1. mvp 및 승률 분석 페이지 작성
   > diary_page에서 기록 > 분석, 분석 > 기록으로 가는 naviagation 설정 필요

   > mvp 및 승률 분석에는 database_helper 활용
2. 최종 테스트를 위한 db 데이터 입력
   > 사진은 photo 테이블에 저장되는 경로 형식을 참고하여 db 데이터 입력

   > 현재 databaes_helper의 db 초기화 메소드는 앱 내부 디렉토리의 db를 삭제하고 재생성 하기에 최종 테스트 시 앱 내부 db 삭제 메소드 주석 처리 필요
3. 앱 화면마다 사용되는 font 적용 수정 필요
   > 토의 후 위젯마다 font를 따로 적용할지 앱 전체에 단일 font를 적용할 지 결정
