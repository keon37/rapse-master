// 글로벌 변수 선언
var currentMenu; // 현재 메뉴
var diseaseType; // 질병 타입
var isApp;

var templates; // handlebars templates

var baseFacilities; // 시설정보
var baseRegions; // 권역 shapefile

var facilityCapacities = {}; // 지역별 처리가능 용적량
var farmUses = {}; // 지역별 농장 1년 평균 사용량
var groupingInfo; // 수동권역화 정보
var clusters = []; // 수동권역화 권역

var map; // leaflet 맵 객체
var mouseHelper; // 권역에 마우스 오버시 시각적 도움을 주는 control
var clusterInfo; // 좌측 상단 권역화 정보 control
var layerControl; // 우측 상단 권역/시설정보 control
var locationControl; // 좌측하단 현재위치 확인 control
var locationControlIonic; // 좌측하단 현재위치 확인 control
var routingControl; // 길찾기 control
var facilityInfo; // 우측 하단 시설정보 테이블 control
var scaleInfo; // 우측 하단 규모정보 control

var baseLayerVWorld; // vworld layer
var baseLayerOSM; // open street map layer

var facilityLayer; // 시설정보 레이어
var facilityGroupLayer = {}; // 시설정보 그룹 레이어
var facilityGroupLabels; // 레이어에 포함될 이름들
var facilityMarker; // 우측 하단 테이블의 row를 클릭했을때 보여지는 시설정보 마커
var clusterLayer; // 권역 레이어
var densityLayer; // 밀집도 레이어
// var bubbles; // 규모 레이어
var scaleLayer; // 규모 레이어 
var scaleGroupLayer = {}; // 규모 그룹 레이어

var selectedClusterId; // 권역 클러스터가 마우스로 클릭되었을때 저장되는 클러스터 ID
var mouseoverRegion; // 권역에 마우스 오버시 임시저장하는 권역명

var clusterColors; // 권역 색상 리스트
// var clusterHighlightColors; // 권역 색상 리스트
// var clusterSelectedColors; // 권역 색상 리스트
var spreadProbabilityColors;

var currentLocation; // 현재 위치
var currentLocationMarker; // 현재 위치 Marker
var destination; // 목적지
var findingRoute = false;

var isMobileOrTablet = isMobileOrTablet();

var test;
var temp;


$(document).ready(function () {
  fixAndBindSizes();
  compileHandlebarsTemplates();
  map = initMap("map");
});


function fixAndBindSizes() {
  fixMapWrapperHeight();
  $(window).resize(function () {
    fixMapWrapperHeight();
    fixBottomRightFacilityInfoSize();
  });
}

function fixMapWrapperHeight() {
  $("#map-wrapper").height($(window).height() - $("#nav-top").outerHeight());
}

function fixBottomRightFacilityInfoSize() {
  $("#map-controls-bottom-facility-info").width(valBetween($(window).width() - 36, 200, 1000));
  // debugger;
  var bottomClusterInfoHeight = 0;
  if ($("#map-controls-bottom-cluster-info").length) {
    bottomClusterInfoHeight = $("#map-controls-bottom-cluster-info").outerHeight();
  }
  var fixHeight = $(window).width() > 600 ? 60 : 0;
  var bottomNavHeight = $("#map-controls-bottom-nav-tab").outerHeight();
  var bottomNavTabHeight = 90 + fixHeight;
  $("#map-controls-bottom-facility-info").height(bottomClusterInfoHeight + bottomNavHeight + bottomNavTabHeight);
  $("#map-controls-bottom-nav-tab-content").height(bottomNavTabHeight);
}

function valBetween(v, min, max) {
  return (Math.min(max, Math.max(min, v)));
}

// leaflet + vworld 지도
function initMap(mapId) {
  var cornerBottomLeft = L.latLng(31.00417864211927, 116.94188229739667);
  var cornerTopRight = L.latLng(44.59036644929533, 139.95678864419463);
  var mapBounds = L.latLngBounds(cornerBottomLeft, cornerTopRight);

  var map_options = {
    minZoom: 6,
    maxZoom: 18,
    maxBounds: mapBounds,
    zoomControl: false
  };

  map = L.map(mapId, map_options).setView([36.4524135030723, 127.8590624034405], 7);

  initBaseLayerVWorld();
  initBaseLayerOpenStreetMap();
  initDefaultBaseLayerByBrowser();

  initClusterLayer();
  initFacilityLayer();
  initFacilityMarker();
  initMapControlZoomAndLayer();

  initDebugging();

  return map;
}

function initBaseLayerVWorld() {
  if (isApp) return;
  var vworldKey = '089C1587-2B3E-3B03-BF67-E4499AFB5000';
  var vworldType = 'Base'; // Base, gray, midnight, Hybrid, Satellite
  var vworldUrl = 'http://api.vworld.kr/req/wmts/1.0.0/{accessKey}/{mapType}/{z}/{y}/{x}.png';
  var vworldAttr = '© <a href="http://dev.vworld.kr">vworld</a>';

  baseLayerVWorld = L.tileLayer(vworldUrl, {
    attribution: vworldAttr,
    accessKey: vworldKey,
    mapType: vworldType
  })
}

function initBaseLayerOpenStreetMap() {
  baseLayerOSM = L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
  });
}

function initDefaultBaseLayerByBrowser() {
  if (isApp) {
    // baseLayerVWorld.addTo(map);
    baseLayerOSM.addTo(map);
  } else if (isMobileOrTablet) {
    baseLayerOSM.addTo(map);
  } else {
    // when desktop
    baseLayerVWorld.addTo(map);
    // baseLayerOSM.addTo(map);
  }

  map.attributionControl.setPosition("bottomleft");
}

// 권역화 레이어
function initClusterLayer() {
  clusterLayer = L.featureGroup();
  clusterLayer.addTo(map);
}

function initFacilityLayer() {
  // 시설정보 레이어 (마커 클러스터링)
  facilityLayer = L.markerClusterGroup({
    disableClusteringAtZoom: (isApp || isMobileOrTablet) ? 9 : 8,
    showCoverageOnHover: false,
    spiderfyOnMaxZoom: true,
    // maxClusterRadius: function (zoom) {
    //   return (zoom <= 9) ? 80 : 1;
    // }
  });

  // facilityLayer.on("click", function (event) {
  //   var feature = event.layer.feature;
  //   // var id = feature.properties.id; var tr =
  //   // $("#map-controls-bottom-nav-tab-content tbody tr[data-facility-id='" + id +
  //   // "']"); console.log(tr);
  // });

  facilityLayer.addTo(map);

  // 시설정보를 항상 권역 레이어 위에 보여주기 위함
  var facilityPane = map.createPane("f");
  facilityPane.style.zIndex = 500;
}

// 권역화 레이어
// function initDensityLayer() {
//   densityLayer = L.featureGroup();
//   densityLayer.addTo(map);
// }

function initFacilityMarker() {
  facilityMarker = L.marker([0, 0]).addTo(map);
}

function hideFacilityMarker() {
  facilityMarker.setLatLng([0, 0]).update();
}

function onLocationFound(e) {
  currentLocation = e.latlng;
  if (findingRoute) {
    findRoute();
  }
}

function initMapControlZoomAndLayer() {
  // 시설정보 컨트롤 추가
  initMapControlRightBottomFacilityInfo();
  initMapControlRightBottomScaleInfo();

  // 현재위치 컨트롤 추가
  if (isApp) {
    initLocationControlIonic();
  } else {
    // if (currentMenu === 'public') {
    locationControl = L.control.locate({
      position: 'bottomright',
      keepCurrentZoomLevel: true,
      strings: {
        title: "현재 위치 확인"
      },
      drawCircle: false,
      // locateOptions: {
      //   enableHighAccuracy: false,
      //   maximumAge: 50000
      // }
    }).addTo(map);

    map.on('locationfound', onLocationFound);
    // }
  }

  // 줌 컨트롤 추가
  new L.Control.Zoom({
    position: 'bottomright'
  }).addTo(map);

  var maps;
  if (isApp) {
    maps = {
      "오픈스트리트 맵": baseLayerOSM,
    };
  } else {
    maps = {
      "브이월드 맵": baseLayerVWorld,
      "오픈스트리트 맵": baseLayerOSM
    };
  }

  layerControl = L.control.groupedLayers(maps, {}, {
    collapsed: false,
    groupCheckboxes: true
  }).addTo(map);

  // control layer를 더블클릭했을때 맵이 줌이되는 버그 fix
  L.DomEvent.disableClickPropagation(layerControl._container);
  L.DomEvent.disableScrollPropagation(layerControl._container);
}

function clearControlsAndMarkers() {
  for (var category in facilityGroupLayer) {
    layerControl.removeLayer(facilityGroupLayer[category]);
  }
  layerControl.removeLayer(clusterLayer);

  clusterLayer.clearLayers();

  facilityLayer.clearLayers();

  facilityGroupLayer = {};
  for (var category in facilityGroupLabels) {
    facilityGroupLayer[facilityGroupLabels[category]] = L.featureGroup.subGroup(facilityLayer);
  }
}

function initDebugging() {
  map.on("click", function (e) {
    console.log(e.latlng.lat + ", " + e.latlng.lng);
  });
}

function showLoading() {
  map.spin(true, {
    color: "#fff",
    opacity: 0.2
  });
  $("#map-loading").show();
}

function hideLoading() {
  map.spin(false);
  $("#map-loading").hide();
}

// 서버처리위함 : [돼지, 소] -> "11"
function getEncodedCheckedValuesFromGroup(selector) {
  return $(selector + " input").map(function () {
    return $(this).prop("checked") ? "1" : "0";
  }).get().join("");
}

function setPositionOfMapControlLeft() {
  var marginTop = $("#map-controls-top-wrapper").outerHeight() + 20;
  $("#map-controls-left-wrapper").css({
    top: marginTop + "px"
  });
}

function setPositionOfMapControlLeftDownload() {
  var marginTop = $("#map-controls-left-wrapper").position().top + $("#map-controls-left-wrapper").outerHeight() + 10;
  $("#map-controls-left-download-wrapper").css({
    top: marginTop + "px"
  });
}

function styleCategory(category) {
  return "<span data-category=" + category + " class='oi oi-media-record' style='color:" + categoryToColor(category) + "'></span> " + category;
}

// style - start

function updateClusterColors(clusterMapping) {
  var maxClusterId = 1;
  for (var key in clusterMapping) {
    var clusterId = clusterMapping[key];
    if (clusterId > maxClusterId) {
      maxClusterId = clusterId;
    }
  }
  clusterColors = chroma.scale("Spectral").colors(maxClusterId);
  // clusterHighlightColors = clusterColors;
  // clusterSelectedColors = clusterColors;
  // clusterHighlightColors = clusterColors.map(function(color) {   return
  // chroma(color); }); clusterSelectedColors = clusterColors.map(function(color)
  // {   return chroma(color); });
}

function categoryToColor(key) {
  if (typeof categoryToColor.colors == "undefined") {
    categoryToColor.colors = {
      "도축장": "#D4376D",
      "도계장": "#D4376D",
      "도압장": "#D4376D",
      "가축분뇨/비료시설": "#F39E27",
      "사료공장": "#76B62A",
      "종축장": "#1F98AC",
      "종계장": "#1F98AC",
      "종압장": "#1F98AC",
      "가축시장": "#2580D3",
      "집유장": "#ced4da",
      "부화장": "#4467E8",
      "철새도래지": "#704FE5",
      "식용란판매업": "#fcc419",
      "AI센터": "#868e96",
      "거점소독시설": "#495057",
      "default": "#212529"
    };
  }
  return categoryToColor.colors[key] || categoryToColor.colors["default"];
}

function clusterToColor(cluster) {
  return clusterColors[cluster - 1];
}

// function clusterToHighlightColor(cluster) {
//   return clusterColors[cluster - 1];
// }

// function clusterToSelectedColor(cluster) {
//   return clusterColors[cluster - 1];
// }

function circleMarkerByCategory(latlng, type) {
  return L.circleMarker(latlng, {
    radius: isMobileOrTablet === true ? 12 : 6,
    weight: 0,
    fillOpacity: 0.8,
    color: categoryToColor(type),
    pane: "f"
  });
}

function clusterStyleNormal(layersClusterId) {
  return {
    fillOpacity: 0.5,
    color: "#868e96",
    fillColor: clusterToColor(layersClusterId),
    weight: 1
  };
}

function clusterStyleHighlighted(layersClusterId) {
  return {
    fillOpacity: 0.65,
    color: "#e03131",
    fillColor: clusterToColor(layersClusterId),
    weight: 3
  };
}

function clusterStyleSelected(layersClusterId) {
  return {
    fillOpacity: 0.8,
    color: "#495057",
    fillColor: clusterToColor(layersClusterId),
    weight: 4
  };
}

function initClusterColor() {
  clusterColors = chroma.scale("Spectral").colors(10);
}

function getClusterPublicColor(number) {
  return clusterColors[number % 10];
}

function getClusterPublicColorRGBA(number) {
  return chroma(getClusterPublicColor(number))
    .alpha(0.7)
    .css();
}

function clusterPublicStyle(clusterId) {
  if (clusterId == -1) {
    return {
      fillOpacity: 0,
      opacity: currentMenu === 'public' ? 0 : 1,
      color: '#868e96',
      weight: 1
    };
  }

  return {
    fillOpacity: 0.6,
    fillColor: getClusterPublicColor(clusterId),
    opacity: 1,
    color: '#212529',
    weight: 1
  };
}

function clusterPublicStyleSelected(clusterId) {
  return {
    fillOpacity: 0.7,
    fillColor: getClusterPublicColor(clusterId),
    opacity: 1,
    color: '#212529',
    weight: 4,
  };
}

// style - end javascript html template 플러그인 관련 로드
function compileHandlebarsTemplates() {
  templates = {};
  templates.form_group = Handlebars.compile($("#templates-form-group").html());
  templates.form_type = Handlebars.compile($("#templates-form-type").html());
  templates.form_checkbox = Handlebars.compile($("#templates-form-checkbox").html());
  templates.form_radio = Handlebars.compile($("#templates-form-radio").html());
  templates.form_select = Handlebars.compile($("#templates-form-select").html());
  templates.form_input_place = Handlebars.compile($("#templates-form-input-place").html());
  templates.slider = Handlebars.compile($("#templates-form-level-slider").html());
  templates.go_button = Handlebars.compile($("#templates-go-button").html());
  templates.clusters_table = Handlebars.compile($("#templates-clusters-table").html());
  templates.clusters_row = Handlebars.compile($("#templates-clusters-row").html());
  templates.clusters_add_button = Handlebars.compile($("#templates-clusters-add-button").html());
  templates.clusters_push_button = Handlebars.compile($("#templates-clusters-push-button").html());
  templates.save_button = Handlebars.compile($("#templates-save-button").html());
  templates.download_link = Handlebars.compile($("#templates-download-link").html());
  templates.table_independence_rate = Handlebars.compile($("#templates-table-independence-rate").html());
  templates.table_facilities_independence_rate = Handlebars.compile($("#templates-table-facilities-independence-rate").html());
  templates.table_facilities_independence_rate_grouping = Handlebars.compile($("#templates-table-facilities-independence-rate-grouping").html());
  templates.table_row_independence_rate = Handlebars.compile($("#templates-table-row-independence-rate").html());
  templates.table_row_independence_rate_for_breakout = Handlebars.compile($("#templates-table-row-independence-rate-for-breakout").html());
  templates.table_row_facility_info = Handlebars.compile($("#templates-table-row-facility-info").html());
  templates.bottom_cluster_info = Handlebars.compile($("#templates-bottom-cluster-info").html());
  templates.tab_head = Handlebars.compile($("#templates-tab-head").html());
  templates.tab_content = Handlebars.compile($("#templates-tab-content").html());
  templates.facility_popup = Handlebars.compile($("#templates-facility-popup").html());
  templates.templates_table_scale_info = Handlebars.compile($("#templates-table-scale-info").html());
  templates.templates_table_row_scale_info = Handlebars.compile($("#templates-table-row-scale-info").html());

  Handlebars.registerHelper("perCentage", function (x) {
    if (isNumeric(x)) {
      return parseFloat(x * 100).toFixed(1) + "%";
    }

    return "NA";
  });

  Handlebars.registerHelper("ifEquals", function (arg1, arg2, options) {
    return arg1 == arg2 ?
      options.fn(this) :
      options.inverse(this);
  });

  Handlebars.registerHelper("encodeMyString", function (inputData) {
    return new Handlebars.SafeString(inputData);
  });

  Handlebars.registerHelper("replaceSlashToDash", function (value) {
    return value.replace("/", "-");
  });

  Handlebars.registerHelper("levelToString", function (level) {
    var levelString = {
      "1": "대",
      "2": "중",
      "3": "소",
      "4": "세분"
    };
    return levelString[level];
  });

  Handlebars.registerHelper("categoryToAbbreviation", function (category) {
    if (category === "가축분뇨처리장") {
      return "분뇨처리장";
    }
    return category;
  });

  Handlebars.registerHelper('formatNumber', function (value) {
    if (value === undefined) {
      return 0;
    }
    return value.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,");
  });
}

function isNumeric(s) {
  return !isNaN(s - parseFloat(s));
}

function setFacilityGroupLabels(groupLabels) {
  facilityGroupLabels = groupLabels;
}

function setFacilityGroupLabelsByDiseaseType(diseaseType) {
  if (diseaseType === 'fmd')
    facilityGroupLabels = ["도축장", "사료공장", "종축장", "AI센터", "가축분뇨/비료시설", "가축시장", "집유장", "거점소독시설", "기타"];

  if (diseaseType === 'hpai')
    facilityGroupLabels = ["도계장", "도압장", "사료공장", "종계장", "종압장", "부화장", "가축분뇨/비료시설", "식용란판매업", "거점소독시설", "기타"];
}

// 우측의 레이어 컨트롤에 보여지는 시설분류정보 순서를 정렬
function sortGroupLayerByLabels(groupLayer, labels) {
  var sortedLayer = {};
  for (var key in labels) {
    var category = labels[key];
    sortedLayer[category] = groupLayer[category];
  }

  return sortedLayer;
}

// 쿼리옵션에 있지 않은 시설정보는 '기타'로 분류
function reclassifyCategoryByOptionFacilities(category) {
  if (contains(["가축분뇨처리장", "비료제조업"], category) === true) {
    return "가축분뇨/비료시설";
  }
  if (contains(facilityGroupLabels, category) === false) {
    return "기타";
  }
  return category;
}

function initMapControlTopType(type) {
  $("#map-controls-top-wrapper").append(templates.form_type(type));
}

function initMapControlTopSpecies(species) {
  $("#map-controls-species").append(templates.form_checkbox(species));
}

function showMapControlTop() {
  $("#map-controls-top-wrapper").removeClass("d-none");
}

// 헬퍼 start
function contains(a, obj) {
  var i = a.length;
  while (i--) {
    if (a[i] === obj) {
      return true;
    }
  }
  return false;
}

// 헬퍼 end

function loadEssentialDatas(diseaseType) {
  $.ajax({
    url: getFacilitiesUrl(diseaseType),
    success: function (json) {
      baseFacilities = json;
    }
  });

  $.ajax({
    url: getRegionUrl(),
    success: function (json) {
      baseRegions = json;
      // 권역 shapefile 용량이 크기 때문에 모두 다운로드 받기 전에 누를 수 없도록
      enableGoButton();
    }
  });
}

function disableGoButton() {
  $("#map-controls-go-button").prop("disabled", true).addClass("btn-secondary");
}

function enableGoButton() {
  $("#map-controls-go-button").prop("disabled", false).removeClass("btn-secondary");
}

function clearBaseDatas() {
  for (var key in baseFacilities) {
    var facility = baseFacilities[key];
    delete facility.properties.cluster;
  }

  for (var key in baseRegions) {
    var region = baseRegions[key];
    delete region.properties.cluster;
    delete region.properties.probability;
  }
}

function clearTables() {
  $("#map-controls-table-independence-rate-body").empty();

  $("#map-controls-bottom-nav-tab").empty();
  $("#map-controls-bottom-nav-tab-content").empty();
}

function goButtonClick(url, args, dataHandler) {
  $.ajax({
    type: "POST",
    url: url,
    data: args,
    beforeSend: function () {
      disableGoButton();
      showLoading();

      clearBaseDatas();
      clearControlsAndMarkers();
      clearTables();

      onNoneClusterClick();
    },
    success: function (json) {
      dataHandler(json);
    },
    error: function (error) {
      console.log(error);
      alert('서버에 오류가 있습니다. 관리자에게 문의 부탁드립니다.');
    },
    complete: function () {
      enableGoButton();
      hideLoading();
    }
  });
}

function addClusterLayerToControl() {
  layerControl.addOverlay(clusterLayer, "<strong>권역</strong>", "권역레이어");
  setTimeout(function () {
    $('#leaflet-control-layers-group-1 .leaflet-control-layers-group-label').hide();
  }, 100);
}

function addDensityLayerToControl() {
  densityGroupLayer = sortGroupLayerByLabels(densityGroupLayer, facilityGroupLabels);
  for (var category in densityGroupLayer) {
    var groupLayer = densityGroupLayer[category];
    layerControl.addOverlay(groupLayer, category, "밀집도 전체");
  }
}

function addScaleLayerToControl() {
  scaleGroupLayer = sortGroupLayerByLabels(scaleGroupLayer, facilityGroupLabels);
  for (var category in scaleGroupLayer) {
    var groupLayer = scaleGroupLayer[category];
    layerControl.addOverlay(groupLayer, category, "규모 전체");
  }
}

function addFacilityLayerToControl() {
  facilityGroupLayer = sortGroupLayerByLabels(facilityGroupLayer, facilityGroupLabels);
  for (var category in facilityGroupLayer) {
    var groupLayer = facilityGroupLayer[category];
    layerControl.addOverlay(groupLayer, styleCategory(category), "시설정보 전체");
  }
}

function fillFacilityInfoTab() {
  var tabs = [];

  for (var index in facilityGroupLabels) {
    tabs.push({
      label: facilityGroupLabels[index]
    });
  }

  $("#map-controls-bottom-nav-tab").append(templates.tab_head(tabs));
  $("#map-controls-bottom-nav-tab-content").append(templates.tab_content(tabs));

  // 스크롤 리셋
  $('a[data-toggle="tab"]').on("shown.bs.tab", function (e) {
    var targetId = $(e.target).attr("href");
    $(targetId).scrollTop(0);
  });
}

function fillFacilityInfoTable(baseFacilities) {
  for (var key in baseFacilities) {
    var facility = baseFacilities[key];

    var cat = reclassifyCategoryByOptionFacilities(facility.properties.cat);
    facility.properties["etc"] = (cat === "기타" || cat === "가축분뇨/비료시설") ? true : false;
    cat = cat.replace("/", "-");
    $("#map-controls-table-body-facility-info-" + cat).append(templates.table_row_facility_info(facility.properties));
  }

  fixBottomRightFacilityInfoSize();

  // 테이블 행 클릭
  $(".facility-info-tbody").on("click", "tr", function (event) {
    var facilityId = parseInt($(event.target).parent().data("facility-id"));
    zoomToFacility(facilityId);
  });

  // 경로탐색 버튼 클릭
  $(".leaflet-popup-pane").on("click", ".btn-find-route", function (event) {
    var dl = $(event.target).closest('dl')
    var facilityId = dl.data('facility-id');
    destination = getFacilityById(facilityId);
    findRoute();
  });

  $(".leaflet-popup-pane").on("click", ".btn-open-map", function (event) {
    var dl = $(event.target).closest('dl')
    var facilityId = dl.data('facility-id');
    var facility = getFacilityById(facilityId);
    var coord = facility.geometry.coordinates;
    var name = facility.properties.name;
    var addr = facility.properties.addr;

    if (isApp) {
      launchNavigatorForIonic(coord[1], coord[0], name, addr);
      // launchNavigatorForMobile(coord[1], coord[0], name, addr);
    } else if (isMobileOrTablet) {
      launchNavigatorForMobile(coord[1], coord[0], name, addr);
    } else {
      launchNavigatorForDesktop(coord[1], coord[0], name);
    }
  });
}

function getFacilityById(facilityId) {
  for (var key in baseFacilities) {
    var facility = baseFacilities[key];
    if (facility.properties.id === facilityId) {
      return facility;
    }
  }
}

function zoomToFacility(facilityId) {
  var facility = getFacilityById(facilityId);
  var coord = facility.geometry.coordinates;
  var latlng = [coord[1], coord[0]];

  if (currentMenu === 'public') {
    hideTopLeftContainer();
    showTopLeftShowButton();
    hideTopRightContainer();
    showTopRightShowButton();

    showFacilityMarkerOnMap(facility.properties.cat);
    var layer = facility.properties.layer;
    facilityLayer.zoomToShowLayer(layer, function () { });
    setTimeout(function () {
      layer.openPopup();
      // updatePopupButton(layer);
    }, 1000);
  } else {
    // 관리자는 마커 띄우기
    map.setView(latlng, 11);
    facilityMarker.setLatLng(latlng).update();
  }
}

// function updatePopupButton(layer) {
//   layer._popup.setContent('something else');
// }

function showIndependenceRateTable() {
  $("#map-controls-left-wrapper").removeClass("d-none");
}

function initMapControlLeftDownloadLink() {
  $("#map-controls-left-download-wrapper").append(templates.download_link({}));
}

function showDownloadLink() {
  $("#map-controls-left-download-wrapper").removeClass("d-none");
}

function onClusterClick(clusterId) {
  selectedClusterId = clusterId;
  $("#map-controls-bottom-facility-info-wrapper").removeClass("d-none");

  // 시설정보 테이블 데이터를 해당권역으로 필터링
  $("#map-controls-bottom-nav-tab-content tbody tr[data-cluster='" + clusterId + "']").attr('class', 'd-table-row');
  $("#map-controls-bottom-nav-tab-content tbody tr[data-cluster!='" + clusterId + "']").attr('class', 'd-none');
  $("#map-controls-bottom-nav-tab-content div.tab-pane.active").scrollTop(0);

  // tab 타이틀을 변경
  $("#map-controls-bottom-nav-tab-content table").each(function () {
    var count = $(this).find("tbody tr[data-cluster='" + clusterId + "']").length;
    var tabId = $(this).closest(".tab-pane").attr("id");
    $("#" + tabId + "-tab").text(tabId.replace("nav-", "").replace("-", "/") + "(" + count + ")");
  });

  hideFacilityMarker();
  fixBottomRightFacilityInfoSize();
}

function onNoneClusterClick() {
  selectedClusterId = -2;
  $("#map-controls-bottom-facility-info-wrapper").addClass("d-none");

  hideFacilityMarker();
}

function bindMapControlTopContainerCloseBtn() {
  $("#map-controls-top-wrapper-close").click(function () {
    $("#map-controls-top-wrapper").animate({
      left: "-600px"
    });
    $("#map-controls-left-wrapper").animate({
      left: "-270px"
    });
    $("#map-controls-left-download-wrapper").animate({
      left: "-195px"
    });
    $("#map-controls-top-wrapper-open").fadeIn();
  });

  $("#map-controls-top-wrapper-open").click(function () {
    $("#map-controls-top-wrapper").animate({
      left: "10px"
    });
    $("#map-controls-left-wrapper").animate({
      left: "10px"
    });
    $("#map-controls-left-download-wrapper").animate({
      left: "10px"
    });
    $("#map-controls-top-wrapper-open").fadeOut();
  });
}

function bindMapControlFacilityInfoCloseBtn() {
  $("#map-controls-facility-info-close").click(function () {
    $("#map-controls-bottom-facility-info").animate({
      marginBottom: -($("#map-controls-bottom-facility-info").outerHeight() + 10),
      marginTop: 45,
    });
    $("#map-controls-facility-info-open").fadeIn();
    $("#map-controls-facility-info-close").fadeOut();
  });

  $("#map-controls-facility-info-open").click(function () {
    $("#map-controls-bottom-facility-info").animate({
      marginBottom: "0px",
      marginTop: "0px",
    });
    $("#map-controls-facility-info-open").fadeOut();
    $("#map-controls-facility-info-close").fadeIn();
  });
}

// array remove
function removeFromArray(arr) {
  var what,
    a = arguments,
    L = a.length,
    ax;
  while (L > 1 && arr.length) {
    what = a[--L];
    while ((ax = arr.indexOf(what)) !== -1) {
      arr.splice(ax, 1);
    }
  }
  return arr;
}

// function showRegions() {
//   for (var key in baseRegions) {
//     var region = baseRegions[key];

//     var layer = L.GeoJSON.geometryToLayer(region);
//     layer.feature = L.GeoJSON.asFeature(region);

//     layer.setStyle(regionStyle);
//     clusterLayer.addLayer(layer);
//   }
// }

function showRegionsAndCluster() {
  for (var key in baseRegions) {
    var region = baseRegions[key];

    var clusterNumber = getClusterNumberByAddr(region.properties.addr_shp);
    region.properties.cluster = clusterNumber;
    var layer = L.GeoJSON.geometryToLayer(region);
    layer.setStyle(clusterPublicStyle(clusterNumber));
    layer.feature = L.GeoJSON.asFeature(region);
    clusterLayer.addLayer(layer);
  }
}

function getClusterByNumber(number) {
  for (var i = 0, iLen = clusters.length; i < iLen; i++) {
    if (clusters[i].number === number)
      return clusters[i];
  }
}

function getClusterNumberByAddr(addr) {
  for (var i = 0, iLen = clusters.length; i < iLen; i++) {
    if (clusters[i].regions.indexOf(addr) != -1)
      return clusters[i].number;
  }
  // 지역명과 매치되는 클러스터 정의가 없다면 -1을 반환
  return -1;
}

function showCluster(clusterNumber, addrs) {
  clusterLayer.eachLayer(function (layer) {
    var addr = layer.feature.properties.addr_shp;
    var exists = (addrs.indexOf(addr) > -1);

    if (exists) {
      layer.setStyle(clusterPublicStyle(clusterNumber));
      layer.bringToFront();
      layer.feature.properties.cluster = clusterNumber;
    }
  });
}

function findRoute() {
  if (currentLocation) {
    findingRoute = false;

    removeRoutingControl();

    var currentLatLng = L.latLng(currentLocation.lat, currentLocation.lng);
    var destinationCoord = destination.geometry.coordinates;
    var destinationLatLng = L.latLng(destinationCoord[1], destinationCoord[0]);

    routingControl = L.Routing.control({
      waypoints: [
        currentLatLng,
        destinationLatLng,
      ],
      collapsible: false,
      serviceUrl: 'https://rapse.ezfarm.co.kr/route/v1',
      createMarker: function (i, waypoint, n) {
        var marker = L.marker(waypoint.latLng, {
          // draggable: true,
          bounceOnAdd: true,
          bounceOnAddOptions: {
            duration: 1000,
            height: 800,
          }
        });
        if (i === n - 1) {
          marker.bindPopup(templates.facility_popup(destination.properties));
        }
        return marker;
      },
    }).addTo(map);

    map.closePopup();
    if (currentMenu === 'public') {
      onNoneClusterClick();
    }
    map.fitBounds(L.latLngBounds(currentLatLng, destinationLatLng));
  } else {
    getCurrentLocation();
  }
}

function getCurrentLocation() {
  findingRoute = true;
  if (isApp) {
    getGeoLocationFromIonic();
  } else {
    locationControl.start();
  }
}

function removeRoutingControl() {
  if (routingControl) {
    map.removeControl(routingControl);
  }
}

function checkFacilityInfoCheckBoxOfLayerControl() {
  $("#leaflet-control-layers-group-2 .leaflet-control-layers-group-selector").attr('checked', true);
}

function isCheckedFacilityInfoCheckBoxOfLayerControl() {
  return $("#leaflet-control-layers-group-2 .leaflet-control-layers-group-selector").is(':checked');
}

function showFacilityMarkersOnMap() {
  if (isCheckedFacilityInfoCheckBoxOfLayerControl() === false) {
    $("#leaflet-control-layers-group-2 .leaflet-control-layers-group-selector").click();
  }
}

function showFacilityMarkerOnMap(category) {
  category = reclassifyCategoryByOptionFacilities(category);
  var checkbox = $("#leaflet-control-layers-group-2 span[data-category='" + category + "']").parent().prev();

  if (checkbox.is(':checked') === false) {
    checkbox.click();
  }
}

function launchNavigatorForMobile(lat, lng, name, addr) {
  if ((navigator.platform.indexOf("iPhone") !== -1) ||
    (navigator.platform.indexOf("iPod") !== -1) ||
    (navigator.platform.indexOf("iPad") !== -1)) {
    window.location = 'navermaps: //?menu=location&pinType=place&lat=' + lat + '&lng=' + lng + '&title=' + name;
  } else {
    window.open('geo:' + lat + ',' + lng + '?q=' + addr, '_system');
  }
}

function launchNavigatorForDesktop(lng, lat, name) {
  var urlNaver = 'https://map.naver.com/?slng=0&slat=0&stext=현재위치&elng={0}&elat={1}&etext={2}&menu=route&pathType=1'.format(lat, lng, name);
  // var urlGoogle = 'https://www.google.com/maps?saddr=My+Location&daddr=' + lat + ',' + lng;
  var win = window.open(urlNaver, '_blank');
  if (win) {
    win.focus();
  } else {
    alert('팝업을 허용해주시기 바랍니다.');
  }
}

function getRegionUrl() {
  var url = "/regions/desktop.json";

  if (location.hostname === "localhost") {
    url = "/regions/mobile.json";
  }

  if (isMobileOrTablet) {
    url = "/regions/mobile.json";
  }

  return url;
}

function getFacilityCapacitiesUrl() {
  return '/api/fac_capa_addr';
}

function getFarmUsesUrl() {
  return '/api/farm_use_fac_addr';
}

function getLivestockCountsUrl() {
  return '/api/livestock_counts';
}

function getFacilitiesUrl(diseaseType) {
  return "/api/facilities/" + diseaseType + "?q=20180721";
}

function getGroupingUrl() {
  return "/api/grouping/" + grouping_no;
}