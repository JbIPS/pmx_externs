package js.pmx;

import js.node.stream.Readable;

typedef PmxOptions = {
  // HTTP routes logging (default: false) 
  @:optional var http: Bool; 
  // Limit of acceptable latency in ms
  @:optional var http_latency : Int;
  // Error code to track' 
  @:optional var http_code: Int;
  // Enable alerts (If you add alert subfield in custom it's going to be enabled) 
  @:optional var alert_enabled: Bool;
  // Ignore http routes with this pattern (default: []) 
  @:optional var ignore_routes: Array<EReg>;
  // Exceptions loggin (default: true) 
  @:optional var errors: Bool;
  // Auto expose JS Loop Latency and HTTP req/s as custom metrics (default: true) 
  @:optional var custom_probes: Bool;
  // Network monitoring at the application level (default: false) 
  @:optional var network: Bool;
  // Shows which ports your app is listening on (default: false) 
  @:optional var ports: Bool;
}

typedef MetricOptions<T> = {
  // The probe name as is will be displayed on the Keymetrics dashboard
  var name: String;
  // Getter called each second to get the value
  @:optional var value: Void -> T;
  // Alert object
  @:optional var alert: MetricAlert<T>;
}

typedef MeterOptions = {
  // The probe name as is will be displayed on the Keymetrics dashboard
  var name: String;
  // Rate unit. Defaults to 1s.
  var samples: Int;
  // Timeframe over which events will be analyzed. Defaults to 60 sec.
  var timeframe: Int;
}

typedef CounterOptions = {
  // The probe name as is will be displayed on the Keymetrics dashboard
  var name: String;
  // It will impact the way the probe data are aggregated within the Keymetrics backend.
  // Use none if this is irrelevant (eg: constant or string value).
  @:optional var agg_type: AggType;
  // Alert object
  @:optional var alert: MetricAlert<Int>;
}

typedef MetricAlert<T> = {
  var mode: AlertMode;
  // Value that will be used for the exception check.
  var value: T;
  // String used for the exception.
  var msg: String;
  // Function triggered when exception reached.
  @:optional var action: Void -> Void;
  // Function used for exception check taking 2 arguments.
  @:optional var cmp: T -> T -> Bool;
  // threshold-avg mode. Sample length for monitored value (180 seconds default).
  @:optional var interval: Int;
  // threshold-avg mode. Time after which mean comparison starts (30 000 milliseconds default).
  @:optional var timeout: Int;
}

@:enum abstract AggType(String) from String to String {
  var Sum = 'sum';
  var Max = 'max';
  var Min = 'min';
  var Avg = 'avg';
  var None = 'none';
}

@:enum abstract AlertMode(String) from String to String {
  var Threshold = 'threshold';
  var ThresholdAverage = 'threshold-avg';
  var Smart = 'smart';
}

@:jsRequire('pmx')
extern class Pmx {
  /**
   * Initialisation method. Starting point
   */
  static function init(options: PmxOptions): Pmx;

  /**
   * Simple action allows to trigger a function from Keymetrics. 
   * The function takes a function as a parameter (reply here) and need to be called once the job is finished.
   */
  function action(actionName: String, callback: (Dynamic -> Void) -> Void): Void;

  /**
   * Scoped Actions are advanced remote actions that can be also triggered from Keymetrics.
   * Two arguments are passed to the function, data (optionnal data sent from Keymetrics) and res that allows to emit log data and to end the scoped action.
   */
  function scopedAction<TSelf: Readable<TSelf>>(actionName: String, callback: Dynamic -> Readable<TSelf>): Void;

  /**
   * Programmatically alert about any critical errors
   */
  @:overload(function(data: String):Void {})
  @:overload(function(error: js.Error):Void {})
  function notify(data: Dynamic): Void;

  /**
   * Emit events and get historical and statistics.
   * This is available in the Events page of Keymetrics.
   */
  function emit(eventName: String, data: Dynamic): Void;

  /**
   * Monitor routes, latency and codes.
   * REST compliant. 
   */
  function http(): Void;

  function probe(): Probe;
}

private extern class Probe {
  /**
   * This allow to expose values that can be read instantly.
   */
  function metric<T>(options: MetricOptions<T>): Metric<T>;

  /**
   * Things that increment or decrement.
   */
  function counter(options: CounterOptions): Counter;

  /**
   * Things that are measured as events / interval.
   */
  function meter(options: MeterOptions): Meter;

  /**
   * Keeps a resevoir of statistically relevant values biased towards the last 5 minutes to explore their distribution.
   */
  function histogram(options: {name: String, measurement: String}): Histogram;
}

private extern class Metric<T> {
  /**
   * Set the new value of the metric
   */
  function set(value: T): Void;
}

private extern class Counter {
  /**
   * Increment the counter
   */
  function inc(): Void;

  /**
   * Decrement the counter
   */
  function dec(): Void;
}

private extern class Meter {
  /**
   * Insert a marker
   */
  function mark(): Void;
}

private extern class Histogram {
  /**
   * Update the histogram
   */
  function update(value: Int): Void;
}
