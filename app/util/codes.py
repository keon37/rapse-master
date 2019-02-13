def dict_to_wtform_choices(dict):
    choices = []
    for key, value in dict.items():
        choices.append((key, value))

    return choices


user_disable = {
    '0': '미승인',
    '1': '승인',
}

job_state = {
    'r': '처리중',
    's': '성공',
    'f': '오류',
}

regions = {
    "모든 지역": "all",
    "서울특별시": "1",
    "부산광역시": "2",
    "대구광역시": "3",
    "인천광역시": "4",
    "광주광역시": "5",
    "대전광역시": "6",
    "울산광역시": "7",
    "세종특별자치시": "8",
    "경기도 수원시": "9",
    "경기도 성남시": "10",
    "경기도 의정부시": "11",
    "경기도 안양시": "12",
    "경기도 부천시": "13",
    "경기도 광명시": "14",
    "경기도 평택시": "15",
    "경기도 동두천시": "16",
    "경기도 안산시": "17",
    "경기도 고양시": "18",
    "경기도 과천시": "19",
    "경기도 구리시": "20",
    "경기도 남양주시": "21",
    "경기도 오산시": "22",
    "경기도 시흥시": "23",
    "경기도 군포시": "24",
    "경기도 의왕시": "25",
    "경기도 하남시": "26",
    "경기도 용인시": "27",
    "경기도 파주시": "28",
    "경기도 이천시": "29",
    "경기도 안성시": "30",
    "경기도 김포시": "31",
    "경기도 화성시": "32",
    "경기도 광주시": "33",
    "경기도 양주시": "34",
    "경기도 포천시": "35",
    "경기도 여주시": "36",
    "경기도 연천군": "37",
    "경기도 가평군": "38",
    "경기도 양평군": "39",
    "강원도 춘천시": "40",
    "강원도 원주시": "41",
    "강원도 강릉시": "42",
    "강원도 동해시": "43",
    "강원도 태백시": "44",
    "강원도 속초시": "45",
    "강원도 삼척시": "46",
    "강원도 홍천군": "47",
    "강원도 횡성군": "48",
    "강원도 영월군": "49",
    "강원도 평창군": "50",
    "강원도 정선군": "51",
    "강원도 철원군": "52",
    "강원도 화천군": "53",
    "강원도 양구군": "54",
    "강원도 인제군": "55",
    "강원도 고성군": "56",
    "강원도 양양군": "57",
    "충청북도 청주시": "58",
    "충청북도 충주시": "59",
    "충청북도 제천시": "60",
    "충청북도 보은군": "61",
    "충청북도 옥천군": "62",
    "충청북도 영동군": "63",
    "충청북도 증평군": "64",
    "충청북도 진천군": "65",
    "충청북도 괴산군": "66",
    "충청북도 음성군": "67",
    "충청북도 단양군": "68",
    "충청남도 천안시": "69",
    "충청남도 공주시": "70",
    "충청남도 보령시": "71",
    "충청남도 아산시": "72",
    "충청남도 서산시": "73",
    "충청남도 논산시": "74",
    "충청남도 계룡시": "75",
    "충청남도 당진시": "76",
    "충청남도 금산군": "77",
    "충청남도 부여군": "78",
    "충청남도 서천군": "79",
    "충청남도 청양군": "80",
    "충청남도 홍성군": "81",
    "충청남도 예산군": "82",
    "충청남도 태안군": "83",
    "전라북도 전주시": "84",
    "전라북도 군산시": "85",
    "전라북도 익산시": "86",
    "전라북도 정읍시": "87",
    "전라북도 남원시": "88",
    "전라북도 김제시": "89",
    "전라북도 완주군": "90",
    "전라북도 진안군": "91",
    "전라북도 무주군": "92",
    "전라북도 장수군": "93",
    "전라북도 임실군": "94",
    "전라북도 순창군": "95",
    "전라북도 고창군": "96",
    "전라북도 부안군": "97",
    "전라남도 목포시": "98",
    "전라남도 여수시": "99",
    "전라남도 순천시": "100",
    "전라남도 나주시": "101",
    "전라남도 광양시": "102",
    "전라남도 담양군": "103",
    "전라남도 곡성군": "104",
    "전라남도 구례군": "105",
    "전라남도 고흥군": "106",
    "전라남도 보성군": "107",
    "전라남도 화순군": "108",
    "전라남도 장흥군": "109",
    "전라남도 강진군": "110",
    "전라남도 해남군": "111",
    "전라남도 영암군": "112",
    "전라남도 무안군": "113",
    "전라남도 함평군": "114",
    "전라남도 영광군": "115",
    "전라남도 장성군": "116",
    "전라남도 완도군": "117",
    "전라남도 진도군": "118",
    "전라남도 신안군": "119",
    "경상북도 포항시": "120",
    "경상북도 경주시": "121",
    "경상북도 김천시": "122",
    "경상북도 안동시": "123",
    "경상북도 구미시": "124",
    "경상북도 영주시": "125",
    "경상북도 영천시": "126",
    "경상북도 상주시": "127",
    "경상북도 문경시": "128",
    "경상북도 경산시": "129",
    "경상북도 군위군": "130",
    "경상북도 의성군": "131",
    "경상북도 청송군": "132",
    "경상북도 영양군": "133",
    "경상북도 영덕군": "134",
    "경상북도 청도군": "135",
    "경상북도 고령군": "136",
    "경상북도 성주군": "137",
    "경상북도 칠곡군": "138",
    "경상북도 예천군": "139",
    "경상북도 봉화군": "140",
    "경상북도 울진군": "141",
    "경상남도 창원시": "142",
    "경상남도 진주시": "143",
    "경상남도 통영시": "144",
    "경상남도 사천시": "145",
    "경상남도 김해시": "146",
    "경상남도 밀양시": "147",
    "경상남도 거제시": "148",
    "경상남도 양산시": "149",
    "경상남도 의령군": "150",
    "경상남도 함안군": "151",
    "경상남도 창녕군": "152",
    "경상남도 고성군": "153",
    "경상남도 남해군": "154",
    "경상남도 하동군": "155",
    "경상남도 산청군": "156",
    "경상남도 함양군": "157",
    "경상남도 거창군": "158",
    "경상남도 합천군": "159",
    "제주특별자치도 제주시": "160",
    "제주특별자치도 서귀포시": "161",
}
