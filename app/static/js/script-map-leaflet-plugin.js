function initMapControlTopLeftClusterInfo() {
  clusterInfo = L.control({
    position: "topleft"
  });

  clusterInfo.onAdd = function (map) {
    this._div = L.DomUtil.create("div", "cluster-info");
    this._div.style.display = 'none';
    return this._div;
  };

  clusterInfo.update = function (json) {
    $(".cluster-info").show();

    if (json && json.clusters) {
      var title = "권역 시작일 : " + json.start_date + "<br>" + "권역 종료일 : " + json.end_date + "<br>";

      var body = '';
      if (json.clusters.length > 0) {
        body += '<table class="cluster-info-table"><tbody>'
        for (var i in json.clusters) {
          var cluster = json.clusters[i];
          body += '<tr><td class="cluster-info-color" style="background:' + getClusterPublicColor(cluster.number) + ';"></td><td class="cluster-info-name">' + cluster.name + '</td></tr>';
        }
        body += '</tbody></table>'
      }

      this._div.innerHTML = title + body;
    } else {
      var title = "설정된 권역 없음<br>";
      this._div.innerHTML = title;
    }
  };

  clusterInfo.addTo(map);
}

function initMapControlRightSpreadProbabilityLegend() {
  var legend = L.control({
    position: "topright"
  });

  legend.onAdd = function (map) {
    var div = L.DomUtil.create("div", "leaflet-control-layers leaflet-control-layers-expanded spread-probability-legend");
    var grades = [
      "0.0 - 0.1",
      "0.1 - 0.2",
      "0.2 - 0.5",
      "0.5 - 1.0",
      "1.0 - 2.0",
      "2.0 - 5.0",
      "5.0 - 10.0",
      "10.0 - Inf"
    ];

    div.innerHTML = "<span class='spread-probability-label'>확산가능성(%)</span>";
    for (var i = 0; i < grades.length; i++) {
      div.innerHTML += '<i style="background:' + spreadProbabilityColors[i] + '"></i> ' + grades[i] + "<br>";
    }

    return div;
  };

  legend.addTo(map);
}

function initMapControlRightMouseHelper() {
  mouseHelper = L.control({
    position: "topright"
  });

  mouseHelper.onAdd = function (map) {
    this._div = L.DomUtil.create("div", "mouse-helper");
    return this._div;
  };

  mouseHelper.update = function (props) {
    if (props) {
      if (mouseoverRegion !== props.addr_shp) {
        mouseoverRegion = props.addr_shp;
        var cluster = props.cluster;

        // "최적권역", "기타권역"으로 들어오지 않고 권역 번호가 들어온다면
        if (cluster) {
          if (!(typeof cluster === "string" || cluster instanceof String)) {
            if (typeof clusters !== 'undefined') {
              // 수동 권역 설정에서 사용
              if (cluster === -1) {
                cluster = "비권역";
              } else {
                if (clusters.length > 0) {
                  cluster = cluster.toString() + " - " + getClusterByNumber(cluster).name;
                } else {
                  cluster = cluster.toString();
                }
              }
            } else {
              //
              cluster = "권역 " + cluster.toString();
            }
          }
          cluster = " - " + cluster;
        } else {
          cluster = '';
        }

        this._div.innerHTML = "<span class='mouse-helper-region'>" + mouseoverRegion.replace("_", " ") + cluster + "</span>";
      }
    } else {
      mouseoverRegion = "";
      this._div.innerHTML = "";
    }
  };

  mouseHelper.addTo(map);
}

function initLocationControlIonic() {
  locationControlIonic = L.control({
    position: "bottomright"
  });

  locationControlIonic.onAdd = function (map) {
    this._div = L.DomUtil.create("div", "leaflet-control-locate-ionic leaflet-bar leaflet-control");
    this._div.innerHTML = '<a class="leaflet-bar-part leaflet-bar-part-single" onclick="getGeoLocationFromIonic();" href="javascript:void(0);"><span class="fa-map-marker fa"></span></a>';

    return this._div;
  };

  locationControlIonic.update = function () {};

  locationControlIonic.addTo(map);
}

function initMapControlRightBottomFacilityInfo() {
  facilityInfo = L.control({
    position: "bottomright"
  });

  facilityInfo.onAdd = function (map) {
    this._div = L.DomUtil.create("div", "d-none");
    L.DomEvent.disableScrollPropagation(this._div);
    L.DomEvent.disableClickPropagation(this._div);
    this._div.setAttribute("id", "map-controls-bottom-facility-info-wrapper");
    this._div.innerHTML = '<div id="map-controls-facility-info-close" class="map-controls-facility-info-close-open-btn" style="right: 5px; top: 3px;"><span class="oi oi-chevron-bottom"></span></div>';
    this._div.innerHTML += '<div id="map-controls-facility-info-open" class="map-controls-facility-info-close-open-btn map-controls" style="display: none; color: #000; right: 0px; top: 0px; border-radius: 4px; background-color: rgba(255, 255, 255, 1);"><span class="oi oi-chevron-top"></span></div>';
    this._div.innerHTML += '<div id="map-controls-bottom-facility-info" class="leaflet-control-layers leaflet-control-layers-expanded"><div id="map-controls-bottom-cluster-info" class="d-none"></div><nav><div class="nav nav-pills mb-1" id="map-controls-bottom-nav-tab" role="tablist"></div></nav><div class="tab-content" id="map-controls-bottom-nav-tab-content"></div>';
    return this._div;
  };

  facilityInfo.addTo(map);
}

function initMapControlRightBottomScaleInfo() {
  scaleInfo = L.control({
    position: "bottomright"
  });

  scaleInfo.onAdd = function (map) {
    this._div = L.DomUtil.create("div", "leaflet-control-layers leaflet-control-layers-expanded leaflet-control d-none");
    L.DomEvent.disableScrollPropagation(this._div);
    L.DomEvent.disableClickPropagation(this._div);
    this._div.setAttribute("id", "map-controls-bottom-scale-info");

    // var scaleTypes = ['닭', '오리', '돼지', '젖소', '고기소', '생산능력', 'TMR'];

    // var scaleTypes = ['산란계', '종계', '육계', '토종닭', '닭 총계', '육용오리', '종오리', '오리 총계', '돼지', '젖소', '고기소', '생산능력', 'TMR'];
    // if (diseaseType === "fmd") {
    //   scaleTypes = ['돼지', '젖소', '고기소', '생산능력', 'tmr'];
    // }
    // if (diseaseType === "hpai") {
    //   scaleTypes = ['닭', '오리', '생산능력'];
    // }

    this._div.innerHTML = templates.templates_table_scale_info({
      'facilityTypes': facilityGroupLabels,
      // 'scaleTypes': scaleTypes,
    });

    return this._div;
  };

  scaleInfo.initClick = function () {
    selectedCategory = facilityGroupLabels[0];
    $("#map-controls-bottom-scale-info-tabs .btn").click(function () {
      $("#map-controls-bottom-scale-info-tabs .btn-primary").removeClass('btn-primary');
      $(this).removeClass('btn-light').addClass('btn-primary');

      selectedCategory = $(this).data('category');
      scaleInfo.updateCountry();
      scaleInfo.updateColumnDisplay();
    });
  }

  scaleInfo.updateColumnDisplay = function () {
    if (selectedCategory === '사료공장') {
      $("#map-controls-bottom-scale-info-table .scale-production").removeClass("d-none");
    } else {
      $("#map-controls-bottom-scale-info-table .scale-production").addClass("d-none");
    }
  }

  scaleInfo.updateRegion = function (addr_shp) {
    if (addr_shp === undefined) {
      var summedScales = {
        'section': '선택 지역',
        'target': '처리량'
      };
      var livestockCounts = {
        'target': '사육수수'
      }
    } else {
      if (facilityScales[addr_shp] !== undefined) {
        var summedScales = this.sumScales(facilityScales[addr_shp][selectedCategory]);
      } else {
        var summedScales = {};
      }
      summedScales['section'] = addr_shp.replace("_", " ");
      summedScales['target'] = '처리량';

      var livestockCounts = baseLivestockCounts[addr_shp];
      livestockCounts['target'] = '사육수수';
    }

    var capacity = templates.templates_table_row_scale_info(summedScales);
    var livestock = templates.templates_table_row_scale_info(livestockCounts);
    $('#map-controls-table-body-scale-info-region').html(capacity + livestock);
    scaleInfo.updateColumnDisplay();
  };

  scaleInfo.updateCluster = function (clusterNumber) {
    if (clusterNumber === -1) {
      var summedScales = {
        'section': '선택 권역',
        'target': '처리량'
      };
      var livestockCounts = {
        'target': '사육수수'
      }
    } else {
      var cluster = getClusterByNumber(clusterNumber);

      var clusterScalesByRegions = [];
      for (var key in cluster.regions) {
        var clusterScalesByRegion = facilityScales[cluster.regions[key]];
        if (clusterScalesByRegion !== undefined) {
          clusterScalesByRegions = clusterScalesByRegions.concat(clusterScalesByRegion[selectedCategory]);
        }
      }

      var summedScales = this.sumScales(clusterScalesByRegions);
      summedScales['section'] = cluster.name || "권역 " + clusterNumber;
      summedScales['target'] = '처리량';
      summedScales['color'] = getClusterPublicColor(clusterNumber);

      var clusterLiveStockByRegions = [];
      for (var key in cluster.regions) {
        clusterLiveStockByRegions = clusterLiveStockByRegions.concat(baseLivestockCounts[cluster.regions[key]]);
      }

      var livestockCounts = this.sumScales(clusterLiveStockByRegions);
      livestockCounts['target'] = '사육수수';
    }

    var capacity = templates.templates_table_row_scale_info(summedScales);
    var livestock = templates.templates_table_row_scale_info(livestockCounts);
    $('#map-controls-table-body-scale-info-cluster').html(capacity + livestock);
    scaleInfo.updateColumnDisplay();
  };

  scaleInfo.updateCountry = function () {
    var summedScales = {
      'section': '전국 총계',
      'target': '처리량'
    };
    var livestockCounts = {
      'target': '사육수수'
    };

    for (var index in baseFacilities) {
      var facility = baseFacilities[index];
      if (facility.properties.cat !== selectedCategory) {
        continue;
      }
      for (var type in facility.properties.scales) {
        if (summedScales[type] === undefined) {
          summedScales[type] = 0;
        }
        summedScales[type] += parseInt(facility.properties.scales[type]);
      }
    }

    var livestockCounts = scaleInfo.sumScales(baseLivestockCounts);
    livestockCounts['target'] = '사육수수';

    var capacity = templates.templates_table_row_scale_info(summedScales);
    var livestock = templates.templates_table_row_scale_info(livestockCounts);

    $('#map-controls-table-body-scale-info-country').html(capacity + livestock);
  };

  scaleInfo.sumScales = function (scalesOfRegion) {
    sum = {};
    for (var index in scalesOfRegion) {
      for (var type in scalesOfRegion[index]) {
        if (sum[type] === undefined) {
          sum[type] = 0;
        }
        sum[type] += parseInt(scalesOfRegion[index][type]);
      }
    }

    return sum;
  }

  scaleInfo.addTo(map);
}