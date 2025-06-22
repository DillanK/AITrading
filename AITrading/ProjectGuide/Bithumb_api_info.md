````
API 이용안내 : https://apidocs.bithumb.com/docs/api-소개
API 요청 수 제한 안내 : https://apidocs.bithumb.com/docs/api-요청-수-제한-안내
인증 헤더 만들기 : https://apidocs.bithumb.com/docs/인증-헤더-만들기
API 주요 에러 코드 : https://apidocs.bithumb.com/docs/api-주요-에러-코드
API 레퍼런스 : https://apidocs.bithumb.com/reference/마켓코드-조회
 : https://api.bithumb.com/v1 으로 시작
 <public api>
  - 마켓 코드 조회 : https://api.bithumb.com/v1/market/all (get)
  - 분(Minute) 캔들 : https://api.bithumb.com/v1/candles/minutes/{unit} (get)
    Request Parameters
     market(String) : 마켓 코드 (ex. KRW-BTC)
     to(String) : 마지막 캔들 시각 (exclusive). ISO8061 포맷 (yyyy-MM-dd'T'HH:mm:ss'Z' or yyyy-MM-dd HH:mm:ss). 기본적으로 KST 기준 시간이며 비워서 요청시 가장 최근 캔들
     count(String) : 캔들 개수(최대 200개까지 요청 가능)
  - 일(Day) 캔들 : https://api.bithumb.com/v1/candles/days (get)
    Request Parameters
     market(String) : 마켓 코드 (ex. KRW-BTC)
     to(String) : 마지막 캔들 시각 (exclusive) ISO8061 포맷 (yyyy-MM-dd'T'HH:mm:ss'Z' 또는 yyyy-MM-dd HH:mm:ss) 기준 시간 KST 비워서 요청시 가장 최근 캔들로 반환됨
     count(String) : 캔들 개수(최대 200개까지 요청 가능)
     convertingPriceUnit(String) : 종가 환산 화폐 단위 (생략할 수 있으며 KRW로 입력한 경우 원화 환산 가격으로 반환됨)
  - 주(Week) 캔들 : https://api.bithumb.com/v1/candles/weeks (get)
    Request Parameters
     market(String) : 마켓 코드 (ex. KRW-BTC)
     to(String) : 마지막 캔들 시각 (exclusive). ISO8061 포맷 (yyyy-MM-dd'T'HH:mm:ss'Z' or yyyy-MM-dd HH:mm:ss). 기본적으로 KST 기준 시간이며 비워서 요청시 가장 최근 캔들
     count(String) : 캔들 개수(최대 200개까지 요청 가능)
  - 월(Month) 캔들 : https://api.bithumb.com/v1/candles/months
    Request Parameters
     market(String) : 마켓 코드 (ex. KRW-BTC)
     to(String) : 마지막 캔들 시각 (exclusive). ISO8061 포맷 (yyyy-MM-dd'T'HH:mm:ss'Z' or yyyy-MM-dd HH:mm:ss). 기본적으로 KST 기준 시간이며 비워서 요청시 가장 최근 캔들
     count(String) : 캔들 개수(최대 200개까지 요청 가능)
  - 최근 체결 내역 : https://api.bithumb.com/v1/trades/ticks (get)
  - 현재가 정보 : https://api.bithumb.com/v1/ticker (get)
  - 호가 정보 조회 : https://api.bithumb.com/v1/orderbook (get)
  - 경보제 : https://api.bithumb.com/v1/market/virtual_asset_warning (get)
````
