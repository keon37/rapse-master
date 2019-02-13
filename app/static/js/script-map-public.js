$(document).ready(function () {
  // if (grouping_no == 0) {
  //   alert('현시간을 기준으로 설정된 권역이 존재하지 않습니다.');
  //   return;
  // }

  showLoading();

  initClusterColor();
  initMapControlTopLeftClusterInfo();
  // clearControlsAndMarkers();
  loadDatas();

  bindMapControlTopLeftContainerCloseBtn();
  hideTopRightContainerNow();
  bindMapControlTopRightContainerCloseBtn();
  initClusterLayerMouseEventForPublic();

  // var marker = L.marker([35.191837109134916, 129.08231735229495]).addTo(map).on('click', findRoute);
  // var marker = L.marker([35.17531671645857, 126.8540668487549]).addTo(map).on('click', findRoute);

  setFacilityGroupLabelsByDiseaseType(diseaseType);

  initMapControlRightMouseHelper();
  $("#map-controls-bottom-cluster-info").removeClass("d-none");

  bindMapControlFacilityInfoCloseBtn();
});

function loadDatas() {
  if (isApp === false) {
    $.when(loadFacilities(), loadRegions(), loadGrouping()).done(function (lf, lr, lg) {
      handleDatas();
    });
  }
}

function loadDatasForIonic() {
  $.when(loadFacilities(), loadGrouping()).done(function (lf, lg) {
    handleDatas();
  });
}

function handleDatas() {
  clearControlsAndMarkers();

  showRegionsAndCluster();
  showFacilities();

  fillFacilityInfoTab();
  fillFacilityInfoTable(baseFacilities);
  hideLoading();
  mapReadyForIonic();
}

function loadFacilities() {
  return $.ajax({
    url: getFacilitiesUrl(diseaseType),
    success: function (json) {
      baseFacilities = json;
    }
  });
}

function loadRegions() {
  return $.ajax({
    url: getRegionUrl(),
    success: function (json) {
      baseRegions = json;
    }
  });
}

function loadGrouping() {
  return $.ajax({
    type: "GET",
    url: getGroupingUrl(),
    success: function (json) {
      groupingInfo = json;
      if (!("clusters" in groupingInfo)) {
        alert('현시간을 기준으로 설정된 권역이 존재하지 않습니다.');
        clusters = [];
      } else {
        clusters = json.clusters;
      }

      clusterInfo.update(groupingInfo);
    }
  });
}

function showFacilities() {
  for (var key in baseFacilities) {
    var facility = baseFacilities[key];
    if (facility.properties.addr_shp) {
      facility.properties.cluster = getClusterNumberByAddr(facility.properties.addr_shp);
    }

    var category = reclassifyCategoryByOptionFacilities(facility.properties.cat);
    var layer = circleMarkerByCategory(L.GeoJSON.coordsToLatLng(facility.geometry.coordinates), category);
    layer.feature = L.GeoJSON.asFeature(facility);
    facility.properties.layer = layer;

    facilityGroupLayer[category].addLayer(layer);
    layer.bindPopup(templates.facility_popup(facility.properties));
  }

  addClusterLayerToControl();
  addFacilityLayerToControl();

  if (!(isApp || isMobileOrTablet)) {
    for (var category in facilityGroupLayer) {
      var groupLayer = facilityGroupLayer[category];
      groupLayer.addTo(map);
    }
  }
  // checkFacilityInfoCheckBoxOfLayerControl();
}

function initClusterLayerMouseEventForPublic() {
  // 클러스터가 아닌 공간이 클릭되면 처리하기 위함
  map.on("click", function (e) {
    if ($(e.originalEvent.target).is("div#map")) {
      hideTopLeftContainer();
      showTopLeftShowButton();
      hideTopRightContainer();
      showTopRightShowButton();
      removeRoutingControl();

      // onNoneClusterClick();

      clusterLayer
        .eachLayer(function (layer) {
          var layersClusterId = layer.feature.properties.cluster;
          if (layersClusterId === -1) return;
          layer.setStyle(clusterPublicStyle(layersClusterId));
        });
    }
  });

  clusterLayer.on("click", function (event) {
    hideTopLeftContainer();
    showTopLeftShowButton();
    hideTopRightContainer();
    showTopRightShowButton();
    removeRoutingControl();

    var clusterId = event.layer.feature.properties.cluster;

    if (clusterId === selectedClusterId) {
      // onNoneClusterClick();

      clusterLayer
        .eachLayer(function (layer) {
          var layersClusterId = layer.feature.properties.cluster;
          if (layersClusterId === -1) return;
          layer.setStyle(clusterPublicStyle(layersClusterId));
        });
    } else {
      updateClusterInfoBottomAndModal(clusterId);
      onClusterClick(clusterId);

      clusterLayer
        .eachLayer(function (layer) {
          var layersClusterId = layer.feature.properties.cluster;
          if (layersClusterId === -1) return;
          if (layersClusterId === clusterId) {
            layer.setStyle(clusterPublicStyleSelected(layersClusterId));
          } else {
            layer.setStyle(clusterPublicStyle(layersClusterId));
            layer.bringToBack();
          }
        });
    }
  });
}

function updateClusterInfoBottomAndModal(clusterId) {
  var cluster = getClusterByNumber(clusterId);

  if (cluster) {
    var clusterColor = getClusterPublicColor(clusterId);
    var clusterName = cluster.name;
    var clusterRegions = cluster.regions.join(", ").replace(/_/g, " ");
  } else {
    var clusterColor = '#cccccc';
    var clusterName = '비권역';
    var clusterRegions = undefined;
  }

  $("#map-controls-bottom-cluster-info").html(templates.bottom_cluster_info({
    "clusterColor": clusterColor,
    "clusterName": clusterName,
    "clusterRegions": clusterRegions,
  }));

  $("#regionsInfoModal .modal-title").html(clusterName + " - 포함지역");
  $("#regionsInfoModal .modal-body").html(clusterRegions);
}

// top left

function bindMapControlTopLeftContainerCloseBtn() {
  $("#map-controls-top-left-show-button").click(function () {
    showTopLeftContainer();
    hideTopLeftShowButton();
  });
}

function hideTopLeftContainer() {
  $('.leaflet-top.leaflet-left').animate({
    'left': "-300px"
  });
}

function showTopLeftContainer() {
  $('.leaflet-top.leaflet-left').animate({
    'left': "0px"
  });
}

function showTopLeftShowButton() {
  $("#map-controls-top-left-show-button").fadeIn();
}

function hideTopLeftShowButton() {
  $("#map-controls-top-left-show-button").fadeOut();
}

// top right

function bindMapControlTopRightContainerCloseBtn() {
  $("#map-controls-top-right-show-button").click(function () {
    showTopRightContainer();
    hideTopRightShowButton();
  });
}

function hideTopRightContainerNow() {
  $('.leaflet-top.leaflet-right').css({
    'right': "-200px"
  });
}

function hideTopRightContainer() {
  $('.leaflet-top.leaflet-right').animate({
    'right': "-200px"
  });
}

function showTopRightContainer() {
  $('.leaflet-top.leaflet-right').animate({
    'right': "0px"
  });
}

function showTopRightShowButton() {
  $("#map-controls-top-right-show-button").fadeIn();
}

function hideTopRightShowButton() {
  $("#map-controls-top-right-show-button").fadeOut();
}

// ionic interface
function bindEvent(element, eventName, eventHandler) {
  if (element.addEventListener) {
    element.addEventListener(eventName, eventHandler, false);
  } else if (element.attachEvent) {
    element.attachEvent('on' + eventName, eventHandler);
  }
}

// Listen to messages from parent window
bindEvent(window, 'message', function (message) {
  // console.log(message);
  var name = message.data.name;
  var data = message.data.data;
  if (name === 'geolocation') {
    var latlng = L.latLng(data[0], data[1]);
    // var accuracy = data[2];

    addCurrentLocationCircle(latlng);
    map.panTo(latlng);

    onLocationFound({
      'latlng': latlng
    });
  }

  if (name === 'regions') {
    baseRegions = data;
    loadDatasForIonic();
  }
});

function addCurrentLocationCircle(latlng) {
  var style = {
    color: '#136AEC',
    fillColor: '#136AEC',
    fillOpacity: 0.15,
    weight: 2,
    opacity: 0.5,
    radius: 10,
  };

  if (currentLocationMarker) {
    map.removeLayer(currentLocationMarker);
  }

  currentLocationMarker = L.circleMarker(latlng, style).addTo(map);
}

function getGeoLocationFromIonic() {
  var message = {
    name: 'geolocation',
  };
  window.parent.postMessage(message, "*");
}

function launchNavigatorForIonic(lat, lng, name, addr) {
  var message = {
    name: 'launchnavigator',
    data: {
      name: name,
      addr: addr,
      lat: lat,
      lng: lng,
    }
  };
  window.parent.postMessage(message, "*");
}

function mapReadyForIonic() {
  var message = {
    name: 'mapready',
  };
  window.parent.postMessage(message, "*");
}