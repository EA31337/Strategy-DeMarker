/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_DeMarker_Params_M15 : DeMarkerParams {
  Indi_DeMarker_Params_M15() : DeMarkerParams(indi_demarker_defaults, PERIOD_M15) {
    period = 8;
    shift = 0;
  }
} indi_demarker_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_DeMarker_Params_M15 : StgParams {
  // Struct constructor.
  Stg_DeMarker_Params_M15() : StgParams(stg_demarker_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0.0;
    signal_open_boost = 1;
    signal_close_method = 2;
    signal_close_level = (float)0.0;
    price_profit_method = 60;
    price_profit_level = (float)0.6;
    price_stop_method = 60;
    price_stop_level = (float)0.6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_demarker_m15;
