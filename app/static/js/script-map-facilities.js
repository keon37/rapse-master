function initForDensity(diseaseType) {
  setFacilityGroupLabelsByDiseaseType(diseaseType);

  loadEssentialDatasForFacilities(densityHandler);
}

function initForScale(diseaseType) {
  setFacilityGroupLabelsByDiseaseType(diseaseType);

  loadEssentialDatasForFacilities(scaleHandler);
}

function densityHandler() {
  dataPoints = {};
  for (var i in baseFacilities) {
    var facility = baseFacilities[i];
    var category = reclassifyCategoryByOptionFacilities(facility.properties.cat);

    if (!(category in dataPoints)) {
      dataPoints[category] = [];
    }

    dataPoints[category].push([facility.geometry.coordinates[1], facility.geometry.coordinates[0]]);
  }

  densityGroupLayer = {};
  for (var i in facilityGroupLabels) {
    var category = facilityGroupLabels[i];
    densityGroupLayer[category] = L.featureGroup.subGroup(densityLayer);
    var heatLayer = L.webGLHeatmap({
      size: 30000,
      units: 'm',
      alphaRange: 0.5,
      opacity: 0.6
    });

    heatLayer.setData(dataPoints[category] || []);
    heatLayer.multiply(2);
    densityGroupLayer[category].addLayer(heatLayer);
    if (category === facilityGroupLabels[0]) {
      densityGroupLayer[category].addTo(map);
    }
  }

  addDensityLayerToControl();
}

// leaflet-heat 플러그인 사용
// function densityHandler2() {
//   dataPoints = {};
//   for (var i in baseFacilities) {
//     var facility = baseFacilities[i];
//     var category = reclassifyCategoryByOptionFacilities(facility.properties.cat);

//     if (!(category in dataPoints)) {
//       dataPoints[category] = [];
//     }

//     dataPoints[category].push([facility.geometry.coordinates[1], facility.geometry.coordinates[0], 1]);
//   }

//   densityGroupLayer = {};
//   for (var i in facilityGroupLabels) {
//     var category = facilityGroupLabels[i];
//     densityGroupLayer[category] = L.featureGroup.subGroup(densityLayer);

//     var heatLayer = L.heatLayer(dataPoints[category] || [], {
//       minOpacity: 0.4,
//       radius: 40,
//       // blur: 15,
//     });
//     densityGroupLayer[category].addLayer(heatLayer);
//     if (category === facilityGroupLabels[0]) {
//       densityGroupLayer[category].addTo(map);
//     }
//   }

//   addDensityLayerToControl();
// }

function createEmptyFeatureCollection() {
  return {
    'type': "FeatureCollection",
    'features': [],
  };
}

function scaleHandler() {
  dataPoints = {};
  for (var i in baseFacilities) {
    var facility = baseFacilities[i];
    var category = reclassifyCategoryByOptionFacilities(facility.properties.cat);

    if (!(category in dataPoints)) {
      dataPoints[category] = createEmptyFeatureCollection();
    }

    dataPoints[category]['features'].push(facility);
  }

  scaleGroupLayer = {};
  for (var i in facilityGroupLabels) {
    var category = facilityGroupLabels[i];
    scaleGroupLayer[category] = L.featureGroup.subGroup(scaleLayer);

    var bubbleLayer = L.bubbleLayer(dataPoints[category] || createEmptyFeatureCollection(), {
      property: "scale",
      legend: false,
      // max_radius: 40,
      tooltip: true,
      scale: false, // not working
      style: {
        radius: 10,
        fillColor: categoryToColor(category),
        color: "#555",
        weight: 1,
        opacity: 0.8,
        fillOpacity: 0.5
      }
    });

    scaleGroupLayer[category].addLayer(bubbleLayer);
    if (category === facilityGroupLabels[0]) {
      scaleGroupLayer[category].addTo(map);
    }
  }

  addScaleLayerToControl();
}

function loadEssentialDatasForFacilities(dataHandler) {
  $.ajax({
    url: getFacilitiesUrl(diseaseType),
    success: function (json) {
      baseFacilities = json;

      clearControlsAndMarkers();

      dataHandler();

      showFacilities();

      fillFacilityInfoTab();
      fillFacilityInfoTable(baseFacilities);

      showBottomWrapper();
    }
  });
}

function showFacilities() {
  for (var key in baseFacilities) {
    var facility = baseFacilities[key];

    var category = reclassifyCategoryByOptionFacilities(facility.properties.cat);
    var layer = circleMarkerByCategory(L.GeoJSON.coordsToLatLng(facility.geometry.coordinates), category);
    layer.feature = L.GeoJSON.asFeature(facility);
    facility.properties.layer = layer;

    facilityGroupLayer[category].addLayer(layer);
    layer.bindPopup(templates.facility_popup(facility.properties));
  }

  addFacilityLayerToControl();
}

function showBottomWrapper() {
  $("#map-controls-bottom-facility-info-wrapper").removeClass("d-none");

  // 시설정보 테이블 데이터를 해당권역으로 필터링
  $("#map-controls-bottom-nav-tab-content tbody tr").attr('class', 'd-table-row');
  $("#map-controls-bottom-nav-tab-content div.tab-pane.active").scrollTop(0);

  // tab 타이틀을 변경
  $("#map-controls-bottom-nav-tab-content table").each(function () {
    var count = $(this).find("tbody tr").length;
    var tabId = $(this).closest(".tab-pane").attr("id");
    $("#" + tabId + "-tab").text(tabId.replace("nav-", "") + "(" + count + ")");
  });

  hideFacilityMarker();
  fixBottomRightFacilityInfoSize();
  bindMapControlFacilityInfoCloseBtn();
}