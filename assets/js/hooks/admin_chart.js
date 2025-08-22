const AdminChart = {
  mounted() {
    this.initializeTranslations()
    this.initializeChart()
  },

  updated() {
    if (this.chart) {
      this.updateChart()
    } else {
      this.initializeTranslations()
      this.initializeChart()
    }
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  },

  initializeTranslations() {
    // Get translations from data attributes or use English fallbacks
    this.translations = {
      registrations: this.el.dataset.labelRegistrations || 'Registrations',
      applications: this.el.dataset.labelApplications || 'Applications',
    }
  },

  initializeChart() {
    const chartType = this.el.dataset.chartType
    const chartData = this.getChartData()

    if (!chartData) return

    const ctx = this.el.getContext('2d')

    const config = this.getChartConfig(chartType, chartData)

    try {
      this.chart = new Chart(ctx, config)
    } catch (error) {
      console.error('Failed to initialize chart:', error)
    }
  },

  updateChart() {
    const chartData = this.getChartData()

    if (!chartData || !this.chart) return

    const chartType = this.el.dataset.chartType

    if (chartType === 'registrations') {
      this.chart.data.labels = chartData.dates
      this.chart.data.datasets[0].data = chartData.registrations
    } else if (chartType === 'applications') {
      this.chart.data.labels = chartData.dates
      this.chart.data.datasets[0].data = chartData.applications
    }

    this.chart.update('none') // Update without animation for smoother refresh
  },

  getChartData() {
    const dataElement = document.getElementById('chart-data')
    if (!dataElement) return null

    try {
      return JSON.parse(dataElement.textContent)
    } catch (error) {
      console.error('Failed to parse chart data:', error)
      return null
    }
  },

  getChartConfig(chartType, data) {
    const baseConfig = {
      type: 'line',
      data: {
        labels: data.dates,
        datasets: [],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            padding: 12,
            titleFont: {
              size: 14,
            },
            bodyFont: {
              size: 13,
            },
            callbacks: {
              title: function (context) {
                const date = new Date(context[0].label)
                return date.toLocaleDateString('de-DE', {
                  weekday: 'long',
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })
              },
            },
          },
        },
        scales: {
          x: {
            display: true,
            grid: {
              display: false,
            },
            ticks: {
              maxRotation: 45,
              minRotation: 45,
              callback: function (value, index) {
                // Show every 5th label to avoid crowding
                if (index % 5 === 0) {
                  const date = new Date(this.getLabelForValue(value))
                  return date.toLocaleDateString('de-DE', {
                    day: '2-digit',
                    month: '2-digit',
                  })
                }
                return ''
              },
            },
          },
          y: {
            display: true,
            beginAtZero: true,
            ticks: {
              stepSize: 1,
              precision: 0,
            },
            grid: {
              borderDash: [3, 3],
            },
          },
        },
      },
    }

    if (chartType === 'registrations') {
      baseConfig.data.datasets.push({
        label: this.translations.registrations,
        data: data.registrations,
        borderColor: 'rgb(123, 78, 171)', // Purple
        backgroundColor: 'rgba(123, 78, 171, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        fill: true,
        pointRadius: 4,
        pointHoverRadius: 6,
      })
    } else if (chartType === 'applications') {
      baseConfig.data.datasets.push({
        label: this.translations.applications,
        data: data.applications,
        borderColor: 'rgb(251, 146, 60)', // Orange
        backgroundColor: 'rgba(251, 146, 60, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        fill: true,
        pointRadius: 4,
        pointHoverRadius: 6,
      })
    }

    return baseConfig
  },
}

export default AdminChart
