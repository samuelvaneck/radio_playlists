<template>
  <div class='flex flex-col'>
    <div id="graph">
      <svg width="100%" height="100%"></svg>
    </div>
    <div id="legend">
      <svg width="100%" height="100%"></svg>
    </div>
  </div>
</template>

<script>
  import * as d3 from 'd3';

  export default {
    props: ['object', 'graphTime'],
    data() {
      return {
        height: 600,
        width: 600,
      }
    },
    created() {
      this.colourScale = d3
        .scaleOrdinal()
        .range(["#5EAFC6", "#FE9922", "#93c464", "#75739F"]);
    },
    watch: {
      graphTime: function(newValue) {
        document.getElementById('graph').getElementsByTagName('svg')[0].innerHTML = '';
        document.getElementById('legend').getElementsByTagName('svg')[0].innerHTML = '';
        this.renderChart(newValue);
      }
    },
    methods: {
      renderChart(timeValue = 'week') {
        const objectType = this.object.hasOwnProperty('artists') ? 'songs' : 'artists';
        fetch(`/${objectType}/${this.object.id}/graph_data?time=${timeValue}`)
          .then(response => response.json())
          .then(data => {
            const radioStationNames = data[data.length-1].columns;
            const stagedData = radioStationNames.flatMap(radioSationName => data.map(d => ({ date: d.date, radioSationName, value: d[radioSationName] })))
            const filteredStagedData = stagedData.filter(element => { return element.date !== undefined });
            const radioStationNamesWithValues = filteredStagedData.filter(element => { return element.value !== 0 })
                                                                  .map(element => element.radioSationName);
            const uniqueStationNames = [...new Set(radioStationNamesWithValues)];

            const chart = StackedBarChart(filteredStagedData, {
              x: d => d.date,
              y: d => d.value,
              z: d => d.radioSationName,
              xDomain: d3.groupSort(data.slice(0, -1), D => d3.sum(D, d => -d.value), d => d.date),
              yLabel: 'Counts',
              zDomain: radioStationNames,
              colors: d3.schemeSpectral[radioStationNames.length],
              width: 500,
              height: 500,
              radioStationNamesLegend: uniqueStationNames,
            })

            document.getElementById('graph').append(chart);

            function StackedBarChart(data, {
              x = (d, i) => i, // given d in data, returns the (ordinal) x-value
              y = d => d, // given d in data, returns the (quantitative) y-value
              z = () => 1, // given d in data, returns the (categorical) z-value
              title, // given d in data, returns the title text
              marginTop = 30, // top margin, in pixels
              marginRight = 0, // right margin, in pixels
              marginBottom = 30, // bottom margin, in pixels
              marginLeft = 40, // left margin, in pixels
              width = 640, // outer width, in pixels
              height = 400, // outer height, in pixels
              xDomain, // array of x-values
              xRange = [marginLeft, width - marginRight], // [left, right]
              xPadding = 0.1, // amount of x-range to reserve to separate bars
              yType = d3.scaleLinear, // type of y-scale
              yDomain, // [ymin, ymax]
              yRange = [height - marginBottom, marginTop], // [bottom, top]
              zDomain, // array of z-values
              offset = d3.stackOffsetDiverging, // stack offset method
              order = d3.stackOrderNone, // stack order method
              yFormat, // a format specifier string for the y-axis
              yLabel, // a label for the y-axis
              colors = d3.schemeTableau10, // array of colors
              legendHeightPosition = 10, // position of the legend, in pixels
              radioStationNamesLegend = [] // array of radio station names to display in the legend
            } = {}) {
              console.log(data);
              // Compute values.
              const X = d3.map(data, x);
              const Y = d3.map(data, y);
              const Z = d3.map(data, z);

              // Compute default x- and z-domains, and unique them.
              if (xDomain === undefined) xDomain = X;
              if (zDomain === undefined) zDomain = Z;
              xDomain = new d3.InternSet(xDomain);
              zDomain = new d3.InternSet(zDomain);

              // Omit any data not present in the x- and z-domains.
              const I = d3.range(X.length).filter(i => xDomain.has(X[i]) && zDomain.has(Z[i]));

              // Compute a nested array of series where each series is [[y1, y2], [y1, y2],
              // [y1, y2], …] representing the y-extent of each stacked rect. In addition,
              // each tuple has an i (index) property so that we can refer back to the
              // original data point (data[i]). This code assumes that there is only one
              // data point for a given unique x- and z-value.
              const series = d3.stack()
                  .keys(zDomain)
                  .value(([x, I], z) => Y[I.get(z)])
                  .order(order)
                  .offset(offset)
                (d3.rollup(I, ([i]) => i, i => X[i], i => Z[i]))
                .map(s => s.map(d => Object.assign(d, {i: d.data[1].get(s.key)})));

              // Compute the default y-domain. Note: diverging stacks can be negative.
              if (yDomain === undefined) yDomain = d3.extent(series.flat(2));

              const parseTimeFormat = {
                'day': '%Y-%m-%dT%H:%M',
                'week': '%Y-%m-%d',
                'month': '%Y-%m-%d',
                'year': '%Y-%m-%d',
                'all': '%Y-%m-%d'
              }
              const xAxisTimeFormat = {
                'day': '%H',
                'week': '%a',
                'month': '%d',
                'year': '%d',
                'all': '%d'
              }
              const parseTime = d3.timeParse(parseTimeFormat[timeValue]);
              const formatTime = d3.timeFormat(xAxisTimeFormat[timeValue]);

              // Construct scales, axes, and formats.
              const xScale = d3.scaleBand(xDomain, xRange).paddingInner(xPadding);
              const yScale = yType(yDomain, yRange);
              const color = d3.scaleOrdinal(zDomain, colors);
              const xAxis = d3.axisBottom(xScale).tickSizeOuter(0).ticks(d3.timeHours, 2).tickFormat((d) => { return formatTime(parseTime(d)) });
              const yAxis = d3.axisLeft(yScale).ticks(height / 60, yFormat);

              // Compute titles.
              if (title === undefined) {
                const formatValue = yScale.tickFormat(100, yFormat);
                title = i => `${X[i]}\n${Z[i]}\n${formatValue(Y[i])}`;
              } else {
                const O = d3.map(data, d => d);
                const T = title;
                title = i => T(O[i], i, data);
              }

              const svg = d3.select('#graph')
                  .selectAll('svg')
                  .attr("width", width)
                  .attr("height", height)
                  .attr("viewBox", [0, 0, width, height])
                  .attr("style", "max-width: 100%; height: auto; height: intrinsic;");

              svg.append("g")
                  .attr("transform", `translate(${marginLeft},0)`)
                  .call(yAxis)
                  .call(g => g.select(".domain").remove())
                  .call(g => g.selectAll(".tick line").clone()
                      .attr("x2", width - marginLeft - marginRight)
                      .attr("stroke-opacity", 0.1))
                  .call(g => g.append("text")
                      .attr("x", -marginLeft)
                      .attr("y", 10)
                      .attr("fill", "currentColor")
                      .attr("text-anchor", "start")
                      .text(yLabel));

              const tooltip = svg.append('g')
                .attr('class', 'tooltip')
                .style('display', 'inline')

              tooltip.append('rect')
                .attr('width', 30)
                .attr('height', 20)
                .attr('fill', 'white')
                .attr('opacity', 0.5)

              tooltip.append('text')
                .attr("x", 15)
                .attr("dy", "1.2em")
                .style("text-anchor", "middle")
                .attr("font-size", "12px")
                .attr("font-weight", "bold")

              const bar = svg.append("g")
                .selectAll("g")
                .data(series)
                .join("g")
                  .attr("fill", ([{i}]) => color(Z[i]))
                .selectAll("rect")
                .data(d => d)
                .join("rect")
                  .attr("x", ({i}) => xScale(X[i]))
                  .attr("y", ([y1, y2]) => Math.min(yScale(y1), yScale(y2)))
                  .attr("height", ([y1, y2]) => Math.abs(yScale(y1) - yScale(y2)))
                  .attr("width", xScale.bandwidth())
                  .on('mouseover', () => { tooltip.style('opacity', 1) })
                  .on('mouseout', () => { tooltip.style('opacity', 0) })
                  .on('mousemove', (event) => {
                    const xPosition = d3.pointer(event)[0] - 15;
                    const yPosition = d3.pointer(event)[1] - 25;
                    tooltip.attr('transform', 'translate (' + xPosition + ',' + yPosition + ')');
                  });

              if (title) bar.append("title")
                  .text(({i}) => title(i));

              const svgLegend = d3.select('#legend')
                .select('svg')
                .attr('width', width)
                .attr('height', 120)
                .attr('viewBox', [0, 0, width, 100])
                .attr('style', 'max-width: 100%; height: auto; height: intrinsic;')

              radioStationNamesLegend.forEach((station , i) => {
                const modulo = i % 3;
                const xPosition = modulo * (width / 3);
                const stationIndex = radioStationNames.indexOf(station);

                svgLegend.append('circle')
                         .attr('cx', marginLeft + xPosition)
                         .attr('cy', legendHeightPosition).attr('r', 6)
                         .attr('fill', colors[stationIndex]);
                svgLegend.append('text')
                         .attr('x', marginLeft + xPosition + 10)
                         .attr('y', legendHeightPosition + 5)
                         .text(station);

                if (modulo === 2) { legendHeightPosition += 30; }
              });

              svg.append("g")
                  .attr("transform", `translate(0,${yScale(0)})`)
                  .call(xAxis);

              return Object.assign(svg.node(), {scales: {color}});
            }

            function lineChart(date) {
              const margin = ({top: 20, right: 20, bottom: 30, left: 40})
              const default_width = 460 - margin.left - margin.right;
              const default_height = 400 - margin.top - margin.bottom;
              const default_ratio = default_width / default_height;
              let width;
              let height;

              function set_size() {
                const current_width = window.innerWidth;
                const current_height = window.innerHeight;
                const current_ratio = current_width / current_height;
                let h;
                let w;
                if (current_ratio > default_ratio) {
                  h = default_height;
                  w = default_width;
                } else {
                  margin.left = 20;
                  w = current_width;
                  h = w / default_ratio;
                }

                width = w - 50 - margin.right;
                height = h - margin.top - margin.bottom;
              }
              set_size()

              const svg = d3.select('#graph')
                            .append('svg')
                            .attr("width", width + margin.left + margin.right)
                            .attr("height", height + margin.top + margin.bottom);
              const g = svg.append("g")
                           .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
              const timeFormat = d3.timeFormat("%d-%b-%y");
              const graphData = data.map(item => {
                return {
                         value: item.value,
                         date: timeFormat(new Date(item.date))
                       }
              });
              function roundUpNearest10(num) {
                return Math.ceil(num / 10) * 10;
              }
              const minDate = d3.min(graphData, d => { return new Date(d.date); });
              const maxDate = d3.max(graphData, d => { return new Date(d.date) } );
              const maxCount = d3.max(graphData, d => { return d.value })

              const dateRange = d3.timeDays(minDate, maxDate, 1)
              const dates = d3.map(graphData, d => { return d.date })
              const newDates = dateRange.map(date => {
                return graphData.find(element => new Date(element) === date) ||  { date: date, value: 0 }
              });

              // X-axis
              const xScale = d3.scaleTime()
                               .domain([minDate, maxDate])
                               .range([0, width]);
              // appand X-axis
              g.append("g")
               .attr("transform", "translate(0," + height + ")")
               .call(d3.axisBottom(xScale).ticks(5));

              // Y-axis
              const yScale = d3.scaleLinear()
                               .domain([0, roundUpNearest10(maxCount)])
                               .range([height, 0]);
              const yAxisTicks = yScale.ticks()
                                       .filter(tick => Number.isInteger(tick));
              const yAxis = d3.axisLeft(yScale)
                              .tickValues(yAxisTicks)
                              .tickFormat(d3.format('d'));
              // append Y-axis
              g.append("g").call(yAxis);

              const line = d3.line()
                .x(d => { return xScale(new Date(d.date)) })
                .y(d => { return yScale(d.value) })

              // append the line
              g.append("path")
               .datum(graphData)
               .attr('fill', 'none')
               .attr('stroke-width', 1,5)
                .attr('stroke', 'black')
               .attr("d", line);
            }
          });
      }
    },
    mounted() {
      this.renderChart()
    }
  }
</script>
