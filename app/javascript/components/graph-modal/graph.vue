<template>
  <div id="graph"></div>
</template>

<script>
  import * as d3 from 'd3';

  export default {
    props: ['object'],
    data() {
      return {
        loadData: {},
        height: 600,
        width: 600
      }
    },
    created() {
      this.colourScale = d3
        .scaleOrdinal()
        .range(["#5EAFC6", "#FE9922", "#93c464", "#75739F"]);
    },
    methods: {
      renderChart() {
        fetch(`/songs/${this.object.id}/graph_data`)
          .then(response => response.json())
          .then(data => {
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
          });
      }
    },
    mounted() {
      this.renderChart()
    }
  }
</script>
