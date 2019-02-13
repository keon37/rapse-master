function initMapControlsForNormal(diseaseType, species, facilities) {
  setFacilityGroupLabelsByDiseaseType(diseaseType);
  initClusterLayerMouseEventForNormal();

  loadEssentialDatas(diseaseType);

  initMapControlTopContainerForNormal();
  bindMapControlTopContainerCloseBtn();
  initMapControlTopType(diseaseType);
  initMapControlTopSpecies(species);
  bindMapControlTopSpeciesWithFacility(species);
  initMapControlTopFacilities(facilities);
  showMapControlTop();
  initMapControlTopLevelForNormal();
  initMapControlTopGoButtonForNormal();

  initMapControlLeftIndepedenceRateForNormal();
  initMapControlLeftDownloadLink();
  setPositionOfMapControlLeft();

  initMapControlRightMouseHelper();

  bindMapControlFacilityInfoCloseBtn();
}

function initMapControlTopContainerForNormal() {
  var options = [{
    label: "축종",
    key: "species",
    required: true
  }, {
    label: "방문시설",
    key: "facilities",
    required: true
  }, {
    label: '<span data-toggle="tooltip" data-placement="top" title="권역화 크기 선택">권역화 단계</span>',
    key: "level"
  }, {
    label: "",
    key: "go"
  }];

  $("#map-controls-top-wrapper").append(templates.form_group(options));
  $('[data-toggle="tooltip"]').tooltip();
}

function bindMapControlTopSpeciesWithFacility(species) {
  for (key in species) {
    var o = species[key];
    $("input[name*='checkbox-" + o.label + "']").change(function (e) {
      var target = $(this).data("bind");
      $("input[name*='checkbox-" + target + "']").prop("disabled", !this.checked);
      $("input[name*='checkbox-" + target + "']").prop("checked", this.checked);
    });
  }
}

function initMapControlTopFacilities(facilities) {
  $("#map-controls-facilities").append(templates.form_checkbox(facilities));
}

function initMapControlTopLevelForNormal() {
  $("#map-controls-level").append(templates.slider({}));
  $("#map-controls-level-slider").slider();
}

function initMapControlTopGoButtonForNormal() {
  $("#map-controls-go").append(templates.go_button({}));
  $("#map-controls-go-button").click(function () {
    if (isFormValidNormal()) {
      goButtonClick("/api/normal", getQueryArgsNormal(), handleJsonDataNormal);
    }
  });
}

function initMapControlLeftIndepedenceRateForNormal() {
  $("#map-controls-left-wrapper").append(templates.table_independence_rate({}));
}

function fillIndependenceRateTableForNormal(independenceRate) {
  $("#map-controls-table-independence-rate-body").append(templates.table_row_independence_rate(independenceRate));
}

function updateDownloadLinkForNormal() {
  $("#map-controls-download-link").attr("href", "/api/normal/download?" + jQuery.param(getQueryArgsNormal()));
}

function getQueryArgsNormal() {
  var type = $("#map-controls-type").val();
  var species = getEncodedCheckedValuesFromGroup("#map-controls-species");
  var facilities = getEncodedCheckedValuesFromGroup("#map-controls-facilities");
  var level = $("#map-controls-level-slider").val();

  var queryArgs = {
    type: type,
    species: species,
    facilities: facilities,
    level: level
  };

  return queryArgs;
}

function handleJsonDataNormal(json) {
  var jsonData = json.clusterMapping;
  updateClusterColors(jsonData);

  for (var key in baseRegions) {
    var region = baseRegions[key];

    var cluster = jsonData[region.properties.addr_shp];
    if (cluster) {
      region.properties.cluster = cluster;
      var layer = L
        .GeoJSON
        .geometryToLayer(region);
      layer.feature = L
        .GeoJSON
        .asFeature(region);
      layer.setStyle(clusterStyleNormal(cluster));
      clusterLayer.addLayer(layer);
    }
  }

  for (var key in baseFacilities) {
    var facility = baseFacilities[key];

    facility.properties.cluster = jsonData[facility.properties.addr_shp];
    var category = reclassifyCategoryByOptionFacilities(facility.properties.cat);
    var layer = circleMarkerByCategory(L.GeoJSON.coordsToLatLng(facility.geometry.coordinates), category);
    layer.feature = L.GeoJSON.asFeature(facility);

    facilityGroupLayer[category].addLayer(layer);
    layer.bindPopup(templates.facility_popup(facility.properties));
  }

  addClusterLayerToControl();
  addFacilityLayerToControl();

  fillIndependenceRateTableForNormal(json.independenceRate);
  showIndependenceRateTable();
  setPositionOfMapControlLeftDownload();
  updateDownloadLinkForNormal();
  showDownloadLink();

  fillFacilityInfoTab();
  fillFacilityInfoTable(baseFacilities);
}

function isFormValidNormal() {
  if ($("#map-controls-species.required :checkbox:checked").length === 0) {
    alert("적어도 하나 이상의 축종을 선택해야 합니다.");
    return false;
  }

  if ($("#map-controls-facilities.required :checkbox:checked:not(:disabled)").length === 0) {
    alert("적어도 하나 이상의 방문시설을 선택해야 합니다.");
    return false;
  }

  return true;
}

function initClusterLayerMouseEventForNormal() {
  clusterLayer
    .on("mouseover", function (event) {
      mouseHelper.update(event.layer.feature.properties);
      var mouseoverClusterId = event.layer.feature.properties.cluster;

      clusterLayer.eachLayer(function (layer) {
        var layersClusterId = layer.feature.properties.cluster;

        if (layersClusterId === mouseoverClusterId) {
          layer.setStyle(clusterStyleHighlighted(layersClusterId));
        }
        if (layersClusterId === selectedClusterId) {
          layer.setStyle(clusterStyleSelected(layersClusterId));
        }
        if (layersClusterId !== mouseoverClusterId && layersClusterId !== selectedClusterId) {
          layer.setStyle(clusterStyleNormal(layersClusterId));
          // bringToFront() <- 호출하는 경우 IE에서 event를 잃어버리는 문제 때문에 아래 method를 사용할 수 밖에 없었음
          layer.bringToBack();
        }
      });
    });

  clusterLayer.on("click", function (event) {
    onClusterClick(event.layer.feature.properties.cluster);
  });

  // 클러스터가 아닌 공간이 클릭되면 처리하기 위함
  map.on("click", function (e) {
    if ($(e.originalEvent.target).is("div#map")) {
      clusterLayer
        .eachLayer(function (layer) {
          var layersClusterId = layer.feature.properties.cluster;
          layer.setStyle(clusterStyleNormal(layersClusterId));
        });
      onNoneClusterClick();
    }
  });

  clusterLayer.on("click mouseout", function (event) {
    clusterLayer
      .eachLayer(function (layer) {
        var layersClusterId = layer.feature.properties.cluster;
        if (layersClusterId === selectedClusterId) {
          layer.setStyle(clusterStyleSelected(layersClusterId));
        } else {
          layer.setStyle(clusterStyleNormal(layersClusterId));
          layer.bringToBack();
        }
      });
  });

  clusterLayer.on("mouseout", function (event) {
    mouseHelper.update(undefined);
  });
}