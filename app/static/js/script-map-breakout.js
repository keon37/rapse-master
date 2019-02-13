function initMapControlsForBreakout(diseaseType, species, weights, optimizations) {
  setFacilityGroupLabelsByDiseaseType(diseaseType);
  initClusterLayerMouseEventForBreakout();

  loadEssentialDatas(diseaseType);

  initMapControlTopContainerForBreakout();
  bindMapControlTopContainerCloseBtn();
  initMapControlTopType(diseaseType);
  initMapControlTopSpecies(species);
  bindMapControlTopSpeciesWithWeight(species);
  initMapControlTopWeight(weights);
  initMapControlTopPlace();
  initMapControlTopOptimization(optimizations);
  showMapControlTop();
  initMapControlTopGoButtonForBreakout();

  initMapControlLeftIndepedenceRateForBreakout();
  initMapControlLeftDownloadLink();
  setPositionOfMapControlLeft();

  initSpreadProbabilityColors();
  initMapControlRightSpreadProbabilityLegend();
  initMapControlRightMouseHelper();

  bindMapControlFacilityInfoCloseBtn();
}

function initMapControlTopContainerForBreakout() {
  var options = [{
    label: "축종",
    key: "species",
    required: true
  }, {
    label: "차량시설별<br>가중치",
    key: "weight",
    required: true
  }, {
    label: "발생지",
    key: "place",
    required: true
  }, {
    label: "시설자립도<br>최적화",
    key: "optimization"
  }, {
    label: "",
    key: "go"
  }];

  $("#map-controls-top-wrapper").append(templates.form_group(options));
}

function bindMapControlTopSpeciesWithWeight(species) {
  for (key in species) {
    var o = species[key];
    $("input[name*='checkbox-" + o.label + "']").change(function (e) {
      var target = $(this)
        .data("bind")
        .split(",");

      for (key in target) {
        $("#select-" + target[key] + "").prop("disabled", !this.checked);
        $("#select-" + target[key] + "").val("0");
      }
    });
  }
}

function initMapControlTopWeight(weights) {
  $("#map-controls-weight").append(templates.form_select(weights));
}

function initMapControlTopPlace() {
  places = [{
    label: "1차"
  }, {
    label: "2차"
  }, {
    label: "3차"
  }];
  $("#map-controls-place").append(templates.form_input_place(places));

  $("#map-controls-place .selectpicker").selectpicker();
  $("#map-controls-place .datepicker").datepicker({
    language: "ko",
    autoclose: true,
    todayHighlight: true
  });

  $("#map-controls-place .input-place-clear-btn").click(function () {
    $(this)
      .siblings(".dropdown")
      .find(".selectpicker")
      .selectpicker("val", "");

    $(this)
      .siblings(".datepicker")
      .datepicker("clearDates");
  });
}

function initMapControlTopOptimization(optimizations) {
  $("#map-controls-optimization").append(templates.form_radio(optimizations));
}

// 조회 버튼 click 시 /api/breakout 호출 
function initMapControlTopGoButtonForBreakout() {
  $("#map-controls-go").append(templates.go_button({}));
  $("#map-controls-go-button").click(function () {
    if (isFormValidBreakout()) {
      goButtonClick("/api/breakout", getQueryArgsBreakout(), handleJsonDataBreakout);
    }
  });
}

//발생시 시설자립도 format init 
function initMapControlLeftIndepedenceRateForBreakout() {
  // 축종 label 추가 
  var label = {
    'species1': '닭',
    'species2': '오리'
  };
  if (diseaseType === 'fmd') {
    label = {
      'species1': '돼지',
      'species2': '소'
    };
  }
  // $("#map-controls-left-wrapper").append(templates.table_facilities_independence_rate({}));
  $("#map-controls-left-wrapper").append(templates.table_facilities_independence_rate(label));
}

// 발생시 시설자립도 값 전달 
function fillIndependenceRateTableForBreakout(independenceRate) {
  $("#map-controls-table-independence-rate-body").append(templates.table_row_independence_rate_for_breakout(independenceRate));
}

function updateDownloadLinkForBreakout() {
  $("#map-controls-download-link").attr("href", "/api/breakout/download?" + jQuery.param(getQueryArgsBreakout()));
}

function getQueryArgsBreakout() {
  var type = $("#map-controls-type").val();
  var species = getEncodedCheckedValuesFromGroup("#map-controls-species");

  var weights = $("#map-controls-weight .weight :selected").text();

  var places = $("#map-controls-place .place").map(function () {
    var region = $(this)
      .find("select")
      .val()
      .replace(" ", "_");
    var date = $(this)
      .find(".datepicker")
      .val();

    // region = "서울특별시"; date = "2018-03-21";
    if (region && date) {
      return region + "|" + date;
    }
  }).get();

  var optimization = $("#map-controls-optimization input:radio[name='radio-optimization']:checked").val();

  var queryArgs = {
    type: type,
    species: species,
    weights: weights,
    places: places,
    optimization: optimization
  };

  return queryArgs;
}

function isFormValidBreakout() {
  if ($("#map-controls-species.required :checkbox:checked").length === 0) {
    alert("적어도 하나 이상의 축종을 선택해야 합니다.");
    return false;
  }

  if ($("#map-controls-weight .weight :selected").text() === "0000000") {
    alert("적어도 하나 이상의 가중치는 1 이상이어야 합니다.");
    return false;
  }

  var placeCount = 0;
  var places = $("#map-controls-place .place");

  for (var i = 0; i < places.length; i++) {
    var place = places.eq(i);
    var region = $(place)
      .find("select")
      .val();
    var date = $(place)
      .find(".datepicker")
      .val();

    if (region && date === "") {
      alert("발생일도 선택해야 합니다.");
      return false;
    }

    if (region === "" && date) {
      alert("발생지도 선택해야 합니다.");
      return false;
    }

    if (region && date) {
      placeCount += 1;
    }
  }

  if (placeCount === 0) {
    alert("하나 이상의 발생지 정보를 입력해야 합니다.");
    return false;
  }

  return true;
}

//goButtonClick 클릭시 호출
function handleJsonDataBreakout(json) {
  var jsonData = json.probabilityAndOptimalCluster;

  for (var key in baseRegions) {
    var region = baseRegions[key];

    var spread_probability = jsonData[region.properties.addr_shp]["prob"];
    var cluster = jsonData[region.properties.addr_shp]["cluster"];
    region.properties.cluster = cluster;

    var layer = L
      .GeoJSON
      .geometryToLayer(region);
    layer.feature = L
      .GeoJSON
      .asFeature(region);

    layer.setStyle(clusterStyleBreakout(spread_probability, cluster));
    clusterLayer.addLayer(layer);
    if (cluster === "기타권역") {
      layer.bringToBack();
    }
  }

  for (var key in baseFacilities) {
    var facility = baseFacilities[key];
    if (facility.properties.addr_shp) {
      if (jsonData[facility.properties.addr_shp]) {
        var cluster = jsonData[facility.properties.addr_shp]["cluster"];
        facility.properties.cluster = cluster;
      }
    }

    var category = reclassifyCategoryByOptionFacilities(facility.properties.cat);
    var layer = circleMarkerByCategory(L.GeoJSON.coordsToLatLng(facility.geometry.coordinates), category);
    layer.feature = L.GeoJSON.asFeature(facility);

    facilityGroupLayer[category].addLayer(layer);
    layer.bindPopup(templates.facility_popup(facility.properties));
  }

  addClusterLayerToControl();
  addFacilityLayerToControl();

  // tbody 부분에 전달 
  // console.log(json)
  fillIndependenceRateTableForBreakout(json.independenceRate);


  showIndependenceRateTable();
  setPositionOfMapControlLeftDownload();
  updateDownloadLinkForBreakout();
  showDownloadLink();

  fillFacilityInfoTab();
  fillFacilityInfoTable(baseFacilities);

}

function initSpreadProbabilityColors() {
  spreadProbabilityColors = chroma
    .scale("YlOrRd")
    .colors(8);
}

function probabilityToColor(probability) {
  if (probability < 0.1) {
    return spreadProbabilityColors[0];
  } else if (probability < 0.2) {
    return spreadProbabilityColors[1];
  } else if (probability < 0.5) {
    return spreadProbabilityColors[2];
  } else if (probability < 1.0) {
    return spreadProbabilityColors[3];
  } else if (probability < 2.0) {
    return spreadProbabilityColors[4];
  } else if (probability < 5.0) {
    return spreadProbabilityColors[5];
  } else if (probability < 10.0) {
    return spreadProbabilityColors[6];
  } else {
    return spreadProbabilityColors[7];
  }
}

function clusterStyleBreakout(probability, cluster) {
  if (cluster === "최적권역") {
    var color = "#212529";
    var weight = 3;
  } else {
    var color = "#868e96";
    var weight = 1;
  }

  return {
    fillOpacity: 0.7,
    color: color,
    fillColor: probabilityToColor(probability),
    weight: weight
  };
}

function initClusterLayerMouseEventForBreakout() {
  clusterLayer.on("mouseover", function (event) {
    mouseHelper.update(event.layer.feature.properties);
  });

  clusterLayer.on("mouseout", function (event) {
    mouseHelper.update(undefined);
  });

  clusterLayer.on("click", function (event) {
    onClusterClick(event.layer.feature.properties.cluster);
  });

  // 클러스터가 아닌 공간이 클릭되면 처리하기 위함
  map.on("click", function (e) {
    if ($(e.originalEvent.target).is("div#map")) {
      onNoneClusterClick();
    }
  });
}