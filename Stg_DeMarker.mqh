/**
 * @file
 * Implements DeMarker strategy based on for the DeMarker indicator.
 */

// User input params.
INPUT string __DeMarker_Parameters__ = "-- DeMarker strategy params --";  // >>> DEMARKER <<<
INPUT float DeMarker_LotSize = 0;                                         // Lot size
INPUT int DeMarker_SignalOpenMethod = 0;                                  // Signal open method (-4-4)
INPUT float DeMarker_SignalOpenLevel = 0.2f;                              // Signal open level (0.0-0.5)
INPUT int DeMarker_SignalOpenFilterMethod = 1;                            // Signal open filter method
INPUT int DeMarker_SignalOpenBoostMethod = 0;                             // Signal open boost method
INPUT int DeMarker_SignalCloseMethod = 0;                                 // Signal close method (-4-4)
INPUT float DeMarker_SignalCloseLevel = 0.2f;                             // Signal close level (0.0-0.5)
INPUT int DeMarker_PriceStopMethod = 0;                                   // Price stop method
INPUT float DeMarker_PriceStopLevel = 0;                                  // Price stop level
INPUT int DeMarker_TickFilterMethod = 1;                                  // Tick filter method
INPUT float DeMarker_MaxSpread = 4.0;                                     // Max spread to trade (pips)
INPUT short DeMarker_Shift = 0;                                           // Shift
INPUT int DeMarker_OrderCloseTime = -20;                                  // Order close time in mins (>0) or bars (<0)
INPUT string __DeMarker_Indi_DeMarker_Parameters__ =
    "-- DeMarker strategy: DeMarker indicator params --";  // >>> DeMarker strategy: DeMarker indicator <<<
INPUT int DeMarker_Indi_DeMarker_Period = 4;               // Period

// Structs.

// Defines struct with default user indicator values.
struct Indi_DeMarker_Params_Defaults : DeMarkerParams {
  Indi_DeMarker_Params_Defaults() : DeMarkerParams(::DeMarker_Indi_DeMarker_Period) {}
} indi_demarker_defaults;

// Defines struct with default user strategy values.
struct Stg_DeMarker_Params_Defaults : StgParams {
  Stg_DeMarker_Params_Defaults()
      : StgParams(::DeMarker_SignalOpenMethod, ::DeMarker_SignalOpenFilterMethod, ::DeMarker_SignalOpenLevel,
                  ::DeMarker_SignalOpenBoostMethod, ::DeMarker_SignalCloseMethod, ::DeMarker_SignalCloseLevel,
                  ::DeMarker_PriceStopMethod, ::DeMarker_PriceStopLevel, ::DeMarker_TickFilterMethod,
                  ::DeMarker_MaxSpread, ::DeMarker_Shift, ::DeMarker_OrderCloseTime) {}
} stg_demarker_defaults;

// Struct to define strategy parameters to override.
struct Stg_DeMarker_Params : StgParams {
  DeMarkerParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_DeMarker_Params(DeMarkerParams &_iparams, StgParams &_sparams)
      : iparams(indi_demarker_defaults, _iparams.tf), sparams(stg_demarker_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_DeMarker : public Strategy {
 public:
  Stg_DeMarker(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_DeMarker *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    DeMarkerParams _indi_params(indi_demarker_defaults, _tf);
    StgParams _stg_params(stg_demarker_defaults);
#ifdef __config__
    SetParamsByTf<DeMarkerParams>(_indi_params, _tf, indi_demarker_m1, indi_demarker_m5, indi_demarker_m15,
                                  indi_demarker_m30, indi_demarker_h1, indi_demarker_h4, indi_demarker_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_demarker_m1, stg_demarker_m5, stg_demarker_m15, stg_demarker_m30,
                             stg_demarker_h1, stg_demarker_h4, stg_demarker_h8);
#endif
    // Initialize indicator.
    DeMarkerParams dm_params(_indi_params);
    _stg_params.SetIndicator(new Indi_DeMarker(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_DeMarker(_stg_params, "DeMarker");
    return _strat;
  }

  /**
   * Check if DeMarker indicator is on buy or sell.
   * Demarker Technical Indicator is based on the comparison of the period maximum with the previous period maximum.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Chart *_chart = sparams.GetChart();
    Indi_DeMarker *_indi = Data();
    bool _is_valid = _indi[_shift].IsValid() && _indi[_shift + 1].IsValid() && _indi[_shift + 2].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result &= _indi[_shift][0] < 0.5 - _level;
          _result &= _indi.IsIncreasing(2);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsIncreasing(3);
            if (METHOD(_method, 1)) _result &= _indi.IsIncByPct(_level);
          }
          break;
        case ORDER_TYPE_SELL:
          _result &= _indi[_shift][0] > 0.5 + _level;
          _result &= _indi.IsDecreasing(2);
          if (_result && _method != 0) {
            if (METHOD(_method, 0)) _result &= _indi.IsDecreasing(3);
            if (METHOD(_method, 1)) _result &= _indi.IsDecByPct(-_level);
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_DeMarker *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 1: {
        int _bar_count1 = (int)_level * (int)_indi.GetPeriod();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count1))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count1));
        break;
      }
      case 2: {
        int _bar_count2 = (int)_level * (int)_indi.GetPeriod();
        _result = _direction < 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count2))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count2));
        break;
      }
    }
    return (float)_result;
  }
};
