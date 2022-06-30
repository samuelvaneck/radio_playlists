<template>
  <div id="graph">

  </div>
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
            const margin = ({top: 10, right: 30, bottom: 30, left: 60})
            const width = 460 - margin.left - margin.right;
            const height = 400 - margin.top - margin.bottom;
            const svg = d3.create("svg")
                          .attr("width", width + margin.left + margin.right)
                          .attr("height", height + margin.top + margin.bottom);
            const svgg = svg.append("g")
                            .attr("transform",
                                  "translate(" + margin.left + "," + margin.top + ")");
            const parseDate = d3.timeFormat("%d-%b-%y");
            const graphData = data.map(item => {
              return {
                       radiostationId: item.radiostation_id,
                       date: parseDate(new Date(item.broadcast_timestamp))
                     }
            });
            const groupGraphData = d3.group(graphData, d => { return d.date })
            console.log(groupGraphData)

            //
            const minDate = d3.min(graphData, d => { return new Date(d.date); });
            const maxDate = d3.max(graphData, d => { return new Date(d.date) } );
            const maxCount = d3.max(groupGraphData, d => { return d[1].length })

            const x = d3.scaleTime()
                        .domain([minDate, maxDate])
                        // .domain(d3.extent(graphData, d => { return d.date }))
                        .range([0, width]);
            svgg.append("g")
                .attr("transform", "translate(0," + height + ")")
                .call(d3.axisBottom(x).ticks(5));

            const y = d3.scaleLinear()
                        .domain([0, maxCount])
                        .range([height, 0]);
            svgg.append("g")
                .call(d3.axisLeft(y));

            const res = Array.from(groupGraphData.keys()); // list of group names
            const color = d3.scaleOrdinal()
                            .domain(res)
                            .range(['#e41a1c','#377eb8','#4daf4a','#984ea3','#ff7f00','#ffff33','#a65628','#f781bf','#999999'])

            svgg.selectAll("path")
                .data(groupGraphData)
                .join("path")
                  .attr('fill', 'none')
                  .attr('stroke-width', 1.5)
                  .attr('stroke', group => color(group[0]))
                  .attr("d", group => {
                      return d3.line()
                        .x(d => x(new Date(d.date)))
                        .y(d => y(group[1].length))
                        (group[1])
                    });
              return(svg.node());
          });
      }
    },
    mounted() {
      this.renderChart()
    }
  }
</script>
