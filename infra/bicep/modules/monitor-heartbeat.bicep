// Azure Monitor heartbeat alert:
// This is the ONLY mechanism that detects the VM itself going down — the monitoring script that
// runs ON that VM cannot detect its own host stopping.

param vmResourceId string
param actionGroupId string

resource heartbeatAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-ipam-worker-vm-heartbeat'
  location: 'global' // metric alerts are always 'global' — no location param needed
  properties: {
    severity: 1
    enabled: true
    scopes: [ vmResourceId ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'VmAvailabilityMetric'
          metricName: 'VmAvailabilityMetric'
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Average'
        }
      ]
    }
    actions: actionGroupId == '' ? [] : [ { actionGroupId: actionGroupId } ]
  }
}
