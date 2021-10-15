function last_two_weeks_diff(dot_id, time, last_data, this_data) {

    var salesChartCanvas = document.getElementById(dot_id).getContext('2d');
  //$('#revenue-chart').get(0).getContext('2d');

  var salesChartData = {
    labels  : time,
    datasets: [
      {
        label               : '本周收益(USD)',
        backgroundColor     : 'rgba(255,123,84,0.1)',
        borderColor         : 'rgba(255,123,84,1)',
        pointRadius         : 4,
        pointColor          : '#3b8bba',
        pointStrokeColor    : 'rgba(255,123,84,1)',
        pointHighlightFill  : '#fff',
        pointHighlightStroke: 'rgba(255,123,84,0.5)',
        data                : this_data
      },
      {
        label               : '上周收益(USD)',
        backgroundColor     : 'rgba(30,174,152, 0.4)',
        borderColor         : 'rgba(30,174,152, 1)',
        pointRadius         : 4,
        pointColor          : 'rgba(30,174,152, 1)',
        pointStrokeColor    : '#c1c7d1',
        pointHighlightFill  : '#fff',
        pointHighlightStroke: 'rgba(30,174,152, 0.5)',
        data                : last_data
      },
    ]
  }

  var salesChartOptions = {
    maintainAspectRatio : false,
    responsive : true,
    legend: {
      display: false
    },
    scales: {
      xAxes: [{
        gridLines : {
          display : false,
        }
      }],
      yAxes: [{
        gridLines : {
          display : true,
          color: '#efefef',
          drawBorder: false,
        }
      }]
    }
  }

  // This will get the first returned node in the jQuery collection.
  var salesChart = new Chart(salesChartCanvas, {
      type: 'line',
      data: salesChartData,
      options: salesChartOptions
    }
  )
}


function hours_24_income(dot_id, time, data) {
    // Sales graph chart
  var salesGraphChartCanvas = document.getElementById(dot_id).getContext('2d');
  //$('#revenue-chart').get(0).getContext('2d');

  var salesGraphChartData = {
    labels  : time,
    datasets: [
      {
        label               : '资产预估(USD)',
        fill                : false,
        borderWidth         : 2,
        lineTension         : 0,
        spanGaps            : true,
        borderColor         : '#4895ef',
        pointRadius         : 2,
        pointHoverRadius    : 3,
        pointColor          : '#000',
        pointBackgroundColor: '#4895ef',
        data                : data
      }
    ]
  }

  var salesGraphChartOptions = {
    maintainAspectRatio : false,
    responsive : true,
    legend: {
      display: false,
    },
    scales: {
      xAxes: [{
        gridLines : {
          display : false,
          drawBorder: false,
        }
      }],
      yAxes: [{
        gridLines : {
          display : true,
          color: '#efefef',
          drawBorder: false,
        }
      }]
    }
  }

  // This will get the first returned node in the jQuery collection.
  var salesGraphChart = new Chart(salesGraphChartCanvas, {
      type: 'line',
      data: salesGraphChartData,
      options: salesGraphChartOptions
    }
  )
}