import { Controller } from "@hotwired/stimulus"
import * as d3 from 'd3';
import { interpolateSpectral } from 'd3-scale-chromatic';

// Connects to data-controller="graph"
export default class extends Controller {
  static value = {
    url: String,
    colourScale: Array,
    timeValue: String,
  }
  initialize() {
    this.colourScale = d3.scaleOrdinal(d3.schemeCategory10)
  }

  async openModal() {
    this.url = this.element.dataset.graphUrl;
    this.timeValue = 'week'
    const modal = document.getElementById('modal-wrapper')
    const url = new URL(this.url)

    modal.setAttribute('data-graph-data-url', url)
    const data = await this.graphData(url)
    this.renderChart(data, this.timeValue)

    modal.classList.remove('hidden')
  }

  async reRenderChart(event) {
    const modal = document.getElementById('modal-wrapper')
    const url = new URL(modal.getAttribute('data-graph-data-url'))
    const clickedBtn = this.element

    this.timeValue = event.params.time
    const data = await this.graphData(url)
    this.clearChart()
    this.setActiveBtn(clickedBtn)
    this.renderChart(data, this.timeValue)
  }

  closeModal() {
    const modal = document.getElementById('modal-wrapper')
    modal.removeAttribute('data-graph-data-url')
    modal.classList.add('hidden')
    this.clearChart()
  }

  async graphData(url) {
    url.searchParams.set('time', this.timeValue)
    const response = await fetch(url)
    return await response.json()
  }

  clearChart() {
    document.getElementById('graph').getElementsByTagName('svg')[0].innerHTML = '';
    document.getElementById('legend').getElementsByTagName('svg')[0].innerHTML = '';
  }

  setActiveBtn(btn) {
    const buttons = document.getElementsByClassName('graph-button');
    for (let button of buttons) {
      button.classList.remove('button-active');
    }
    btn.classList.add('button-active');
  }

  renderChart(data, timeValue) {
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
      colors: radioStationNames.map((d, i) => { return interpolateSpectral(i/radioStationNames.length) }),
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
      marginBottom = 40, // bottom margin, in pixels
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
      colors = radioStationNames.map((d, i) => { return interpolateSpectral(i/radioStationNames.length) }), // array of colors
      legendHeightPosition = 10, // position of the legend, in pixels
      radioStationNamesLegend = [] // array of radio station names to display in the legend
    } = {}) {
      // Compute values.
      const X = d3.map(data, x);
      const Y = d3.map(data, y);
      const Z = d3.map(data, z);
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
        'month': '%e %b',
        'year': '%b %g',
        'all': '%b %g'
      }

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

      const parseTime = d3.timeParse(parseTimeFormat[timeValue]);
      const formatTime = d3.timeFormat(xAxisTimeFormat[timeValue]);

      // Construct scales, axes, and formats.
      const xScale = d3.scaleBand(xDomain, xRange).paddingInner(xPadding);
      const yScale = yType(yDomain, yRange);
      const color = d3.scaleOrdinal(zDomain, colors);
      const xAxis = d3.axisBottom(xScale)
          .tickSizeOuter(0)
          .tickFormat((d) => { return formatTime(parseTime(d)) });
      const yAxis = d3.axisLeft(yScale)
          .ticks(height / 60, yFormat);

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
          .call(xAxis)
          .selectAll("text")
          .style("text-anchor", "end")
          .attr("dx", "-.8em")
          .attr("dy", ".15em")
          .attr("transform", "rotate(-65)");

      return Object.assign(svg.node(), {scales: {color}});
    }
  }
}
