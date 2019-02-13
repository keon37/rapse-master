var clusters;
var facilityScales; // 시설정보 by 지역 & 시설종류
var baseLivestockCounts;
var selectedCategory;

setFacilityGroupLabelsByDiseaseType(diseaseType);

$(document).ready(function () {
  initMapControlsForGrouping();
});

function initMapControlsForGrouping() {
  initClusterLayerMouseEventForGrouping();
  initClusterColor();

  loadFacilities();
  loadRegions();
  loadLivestockCounts();
  loadIndependenceRateData();

  initMapControlTopContainerForGrouping();
  bindMapControlTopContainerCloseBtn();
  initMapControlTopGroupingControlForGrouping();
  initMapControlTopGoButtonForGrouping();
  initMapControlTopPushNotificationPopupBtn();

  initMapControlTopPushNotificationSendBtn();


  initPeriodData();

  showMapControlTop();
  showMapControlBottomRight();
  initMapControlRightMouseHelper();
  initMapControlTopGroupingControlEvent();

  initMapControlLeftIndepedenceRateForGrouping();
  showIndependenceRateTable();
  setPositionOfMapControlLeft();
  // setPositionOfMapControlLeftDownload();

  initMapControlLeftDownloadLink();

  bindMapControlFacilityInfoCloseBtn();

  scaleInfo.initClick();
}

function initMapControlTopPushNotificationPopupBtn() {
  $('#pushNotificationModal').on('show.bs.modal', function (e) {
    var clusterNumber = $(e.relatedTarget).closest('tr').data('cluster-number');
    var clusterName = '';
    var clusterRegions = '';
    if (clusterNumber) {
      var cluster = getClusterByNumber(clusterNumber);
      clusterName = cluster.name;
      clusterRegions = cluster.regions.join(", ").replace(/_/g, " ");
    } else {
      var clusterNumber = '0';
      var clusterName = '권역이 설정된 전체 지역';
      var regions = [];
      for (let index = 0; index < clusters.length; index++) {
        regions = regions.concat(clusters[index].regions);
      }
      clusterRegions = regions.join(", ").replace(/_/g, " ");
    }

    $('#push-notification-cluster-number').html(clusterNumber);
    $('#push-notification-cluster-name').html(clusterName);
    $('#push-notification-cluster-regions').html(clusterRegions);

    $('#push-notification-message-title').val("");
    $('#push-notification-message-body').val("");
  })
}


function initMapControlTopPushNotificationSendBtn() {
  initPushNotificationSendBtn(getTopicPushNotificationData, '/api/push/send/topics');
}

function initMapControlLeftIndepedenceRateForGrouping() {
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
  $("#map-controls-left-wrapper").append(templates.table_facilities_independence_rate_grouping(label));
}

function getTopicPushNotificationData() {
  return {
    "diseaseType": diseaseType,
    "topics": $.map($('#push-notification-cluster-regions').html().split(","), $.trim),
    "title": $('#push-notification-message-title').val(),
    "body": $('#push-notification-message-body').val(),
  };
}

function loadFacilities() {
  return $.ajax({
    url: getFacilitiesUrl(diseaseType),
    success: function (json) {
      baseFacilities = json;

      initFacilityScales();
      clearControlsAndMarkers();
      showFacilities();

      scaleInfo.updateRegion(undefined);
      scaleInfo.updateCluster(-1);
      scaleInfo.updateCountry();
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

function initFacilityScales() {
  facilityScales = {};
  for (let index = 0; index < baseFacilities.length; index++) {
    var facility = baseFacilities[index];
    var addr_shp = facility.properties.addr_shp;
    var category = facility.properties.cat;
    if (facilityScales[addr_shp] === undefined) {
      facilityScales[addr_shp] = [];
    }
    if (facilityScales[addr_shp][category] === undefined) {
      facilityScales[addr_shp][category] = [];
    }
    facilityScales[addr_shp][category].push(facility.properties.scales);
  }
}

function loadRegions() {
  $.ajax({
    url: getRegionUrl(),
    success: function (json) {
      baseRegions = json;
      enableSaveButton();
      enableClustersAddButton();
      enablePushButton();
      loadGroupingData();
    }
  });
}

function loadLivestockCounts() {
  $.ajax({
    url: getLivestockCountsUrl(),
    success: function (json) {
      baseLivestockCounts = json;
    }
  });
}

function loadIndependenceRateData() {
  $.ajax({
    url: getFacilityCapacitiesUrl(),
    success: function (json) {
      facilityCapacities = json;
    }
  });

  $.ajax({
    url: getFarmUsesUrl(),
    success: function (json) {
      farmUses = json;
    }
  });
}

function enableSaveButton() {
  $("#map-controls-save-button").prop("disabled", false).removeClass("btn-secondary");
}

function enableClustersAddButton() {
  $("#map-controls-clusters-add-button").prop("disabled", false).removeClass("btn-secondary");
}

function enablePushButton() {
  $("#map-controls-clusters-push-button").prop("disabled", false).removeClass("btn-secondary");
  // $('#map-controls-clusters-push-button').modal();
}

function updateDownloadLinkForGrouping() {
  $("#map-controls-download-link").attr("href", "/api/grouping/download?" + jQuery.param({
    "grouping_no": grouping_no,
  }));
}

function loadGroupingData() {
  $.ajax({
    type: "GET",
    url: getGroupingUrl(),
    success: function (json) {
      var clustersFromServer = json.clusters;

      showRegionsAndCluster();

      if (clustersFromServer instanceof Array) {
        for (var i in clustersFromServer) {
          var cluster = clustersFromServer[i];
          addClusterRow(cluster.number, cluster.name);
          showCluster(cluster.number, cluster.regions);
        }
        clusters = clustersFromServer;
      } else {
        addClusterRow();
      }

      setPositionOfMapControlLeft();
      setPositionOfMapControlLeftDownload();
      updateDownloadLinkForGrouping();
      showDownloadLink();
    }
  });
}

// function setPositionOfMapControlLeftDownload() {
//   var marginTop = $("#map-controls-top-wrapper").position().top + $("#map-controls-top-wrapper").outerHeight() + 10;
//   $("#map-controls-left-download-wrapper").css({
//     top: marginTop + "px"
//   });
// }

function initMapControlTopContainerForGrouping() {
  var options = [{
    label: "기간",
    key: "period",
  }, {
    label: "권역 리스트",
    key: "clusters",
  }, {
    label: "",
    key: "clusters-control",
  }, {
    label: "",
    key: "save"
  }];

  $("#map-controls-top-wrapper").append(templates.form_group(options));
}

function initPeriodData() {
  $("#map-controls-period").append('<p>' + grouping_period + '</p>');
}

function showMapControlTop() {
  $("#map-controls-top-wrapper").removeClass("d-none");
}

function showMapControlBottomRight() {
  $("#map-controls-bottom-scale-info").removeClass("d-none");
}

function addClusterRow(number, name) {
  number = typeof number !== 'undefined' ? number : getLastClusterNumber() + 1;
  name = typeof name !== 'undefined' ? name : "권역 " + number;

  var cluster = {
    "number": number,
    "name": name,
    "regions": []
  };

  clusters.push(cluster);

  var cluster_row = {
    "number": number,
    "name": name,
    "color": getClusterPublicColorRGBA(number),
  };

  $("#map-controls-clusters-body").append(templates.clusters_row(cluster_row));
  selectClusterRowByNumber(number);
}

function removeClusterByNumber(number) {
  for (var i = 0, iLen = clusters.length; i < iLen; i++) {
    if (clusters[i].number === number) {
      clusters.splice(i, 1);
      break;
    }
  }
}

function getClusterRowByNumber(clusterNumber) {
  return $("#map-controls-clusters-body tr[data-cluster-number='" + clusterNumber + "']");
}

function selectClusterRowByNumber(clusterNumber) {
  $('#map-controls-clusters-body tr').removeClass('cluster-selected');
  getClusterRowByNumber(clusterNumber).addClass('cluster-selected');
  selectedClusterId = clusterNumber;
}

function initMapControlTopGroupingControlForGrouping() {
  $("#map-controls-clusters-control").append(templates.clusters_add_button());
  $("#map-controls-clusters-control").append(templates.clusters_push_button());
  $("#map-controls-clusters").append(templates.clusters_table({}));

  $("#map-controls-clusters-add-button").click(function () {
    addClusterRow();
    setPositionOfMapControlLeftDownloadForGrouping();
  });

}

function initMapControlTopGroupingControlEvent() {
  $(document).on('click', '.cluster-select-btn', function () {
    clusterNumber = $(this).closest('tr').data('cluster-number');
    selectClusterRowByNumber(clusterNumber);
  });

  $(document).on('click', '#map-controls-clusters-body tr .close', function () {
    var clusterNumber = $(this).closest('tr').data('cluster-number');
    getClusterRowByNumber(clusterNumber).remove();
    removeCluster(clusterNumber);
    setPositionOfMapControlLeftDownloadForGrouping();
  });

  $(document).on('change paste keyup', '.cluster-name-input', function () {
    var clusterNumber = $(this).closest('tr').data('cluster-number');
    var cluster = getClusterByNumber(clusterNumber);
    cluster.name = $(this).val();
  });
}

function countClusters() {
  return $("#map-controls-clusters-body tr").length;
}

function getLastClusterNumber() {
  var number = 0;
  for (var i in clusters) {
    if (number < clusters[i].number) {
      number = clusters[i].number;
    }
  }

  return number;
}

function initMapControlTopGoButtonForGrouping() {
  $("#map-controls-save").append(templates.save_button(diseaseType));
  $("#map-controls-save-button").click(function () {
    var data = {
      'method': 'save',
      "grouping_no": grouping_no,
      "clusters": clusters,
    };

    $.ajax({
      type: "POST",
      url: "/api/grouping",
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(data),
      success: function (json) {
        alert('데이터가 저장되었습니다.');
      }
    });
  });
}

function updateIndependenceRateOfCluster(clusterNumber) {
  var target_body = $("#map-controls-table-independence-rate-body-grouping");

  if (clusterNumber === -1) {
    target_body.find('#f1-v1').text('');
    target_body.find('#f1-v2').text('');
    target_body.find('#f2-v1').text('');
    target_body.find('#f2-v2').text('');
    target_body.find('#f3-v1').text('');
    target_body.find('#f3-v2').text('');
    target_body.find('#f4-v1').text('');
    target_body.find('#f4-v2').text('');
  } else {
    var cluster = getClusterByNumber(clusterNumber);

    var sumOfFacilityCapacities = new Array(16);
    var sumOfFarmUses = new Array(16);
    for (var key in cluster.regions) {
      cluster_addr = cluster.regions[key];

      var targetFacilityCapacities = facilityCapacities[cluster_addr];
      targetFacilityCapacities.forEach(function (targetData, i) {
        sumOfFacilityCapacities[i] = (sumOfFacilityCapacities[i] || 0) + targetData;
      });

      var targetFarmUses = farmUses[cluster_addr];
      targetFarmUses.forEach(function (targetData, i) {
        sumOfFarmUses[i] = (sumOfFarmUses[i] || 0) + targetData;
      });
    }

    independenceRates = new Array(16);
    sumOfFacilityCapacities.forEach(function (targetData, i) {
      if (sumOfFarmUses[i] === 0) {
        independenceRates[i] = 100;
      } else {
        independenceRates[i] = Math.min(((((sumOfFacilityCapacities[i] / 1.5) - sumOfFarmUses[i]) / sumOfFarmUses[i]) + 1) * 100, 100);
      }
    });

    if (diseaseType === 'fmd') {
      target_body.find('#f1-v1').text(independenceRates[8].toFixed(1) + '%');
      target_body.find('#f1-v2').text(independenceRates[12].toFixed(1) + '%');
      target_body.find('#f2-v1').text(independenceRates[9].toFixed(1) + '%');
      target_body.find('#f2-v2').text(independenceRates[13].toFixed(1) + '%');
      target_body.find('#f3-v1').text(independenceRates[10].toFixed(1) + '%');
      target_body.find('#f3-v2').text(independenceRates[14].toFixed(1) + '%');
      target_body.find('#f4-v1').text(independenceRates[11].toFixed(1) + '%');
      target_body.find('#f4-v2').text(independenceRates[15].toFixed(1) + '%');
    } else {
      target_body.find('#f1-v1').text(independenceRates[0].toFixed(1) + '%');
      target_body.find('#f1-v2').text(independenceRates[4].toFixed(1) + '%');
      target_body.find('#f2-v1').text(independenceRates[1].toFixed(1) + '%');
      target_body.find('#f2-v2').text(independenceRates[5].toFixed(1) + '%');
      target_body.find('#f3-v1').text(independenceRates[2].toFixed(1) + '%');
      target_body.find('#f3-v2').text(independenceRates[6].toFixed(1) + '%');
      target_body.find('#f4-v1').text(independenceRates[3].toFixed(1) + '%');
      target_body.find('#f4-v2').text(independenceRates[7].toFixed(1) + '%');
    }
  }
}

function initClusterLayerMouseEventForGrouping() {
  clusterLayer.on("mouseover", function (event) {
    mouseHelper.update(event.layer.feature.properties);
    scaleInfo.updateCluster(event.layer.feature.properties.cluster);
    scaleInfo.updateRegion(event.layer.feature.properties.addr_shp);
    updateIndependenceRateOfCluster(event.layer.feature.properties.cluster);
  });

  clusterLayer.on("mouseout", function (event) {
    mouseHelper.update(undefined);
    scaleInfo.updateRegion(undefined);
  });

  clusterLayer.on("click", function (event) {
    onRegionClick(event.layer);
    // onClusterClick(event.layer.feature.properties.cluster);
  });

  // // 클러스터가 아닌 공간이 클릭되면 처리하기 위함
  // map.on("click", function (e) {
  //   if ($(e.originalEvent.target).is("div#map")) {
  //     onNoneClusterClick();
  //   }
  // });
}

function removeCluster(number) {
  var cluster = getClusterByNumber(number);

  clusterLayer.eachLayer(function (layer) {
    var addr = layer.feature.properties.addr_shp;
    var exists = (cluster.regions.indexOf(addr) > -1);

    if (exists) {
      layer.setStyle(clusterPublicStyle(-1));
      layer.bringToBack();
      layer.feature.properties.cluster = -1;
    }
  });

  removeClusterByNumber(number);
  selectClusterRowByNumber(getLastClusterNumber());
}

function onRegionClick(layer) {
  var addr = layer.feature.properties.addr_shp;

  if (layer.feature.properties.cluster > 0) {
    // 권역에 추가되었던 지역이라면
    var cluster = getClusterByNumber(layer.feature.properties.cluster);
    removeFromArray(cluster.regions, addr);
    setLayersStyleAndClusterId(addr, clusterPublicStyle(-1), true);
    mouseHelper.update(undefined);
    scaleInfo.updateCluster(-1);
    updateIndependenceRateOfCluster(-1);
  } else {
    // 권역에 추가되지 않았던 지역이라면
    var cluster = getClusterByNumber(selectedClusterId);
    cluster.regions.push(addr);
    setLayersStyleAndClusterId(addr, clusterPublicStyle(selectedClusterId), false);
    mouseHelper.update(layer.feature.properties);
    scaleInfo.updateCluster(selectedClusterId);
    updateIndependenceRateOfCluster(selectedClusterId);
  }
}

function setLayersStyleAndClusterId(addr, style, remove) {
  clusterLayer.eachLayer(function (layer) {
    if (layer.feature.properties.addr_shp === addr) {
      layer.setStyle(style);

      if (remove) {
        layer.bringToBack();
        layer.feature.properties.cluster = -1;
      } else {
        layer.bringToFront();
        layer.feature.properties.cluster = selectedClusterId;
      }
    }
  });
}