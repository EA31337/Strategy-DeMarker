/**
 * @file
 * Implements DeMarker strategy based on for the DeMarker indicator.
 */

// User input params.
INPUT_GROUP("DeMarker strategy: strategy params");
INPUT float DeMarker_LotSize = 0;                // Lot size
INPUT int DeMarker_SignalOpenMethod = 0;         // Signal open method (-127-127)
INPUT float DeMarker_SignalOpenLevel = 0.2f;     // Signal open level (0.0-0.5)
INPUT int DeMarker_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int DeMarker_SignalOpenFilterTime = 3;     // Signal open filter time
INPUT int DeMarker_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int DeMarker_SignalCloseMethod = 0;        // Signal close method (-127-127)
INPUT int DeMarker_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT float DeMarker_SignalCloseLevel = 0.2f;    // Signal close level (0.0-0.5)
INPUT int DeMarker_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float DeMarker_PriceStopLevel = 2;         // Price stop level
INPUT int DeMarker_TickFilterMethod = 32;        // Tick filter method
INPUT float DeMarker_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short DeMarker_Shift = 0;                  // Shift
INPUT float DeMarker_OrderCloseLoss = 80;        // Order close loss
INPUT float DeMarker_OrderCloseProfit = 80;      // Order close profit
INPUT int DeMarker_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("DeMarker strategy: DeMarker indicator params");
INPUT int DeMarker_Indi_DeMarker_Period = 23;  // Period
INPUT int DeMarker_Indi_DeMarker_Shift = 0;    // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_DeMarker_Params_Defaults : DeMarkerParams {
  Indi_DeMarker_Params_Defaults() : DeMarkerParams(::DeMarker_Indi_DeMarker_Period, ::DeMarker_Indi_DeMarker_Shift) {}
};

// Defines struct with default user strategy values.
struct Stg_DeMarker_Params_Defaults : StgParams {
  Stg_DeMarker_Params_Defaults()
      : StgParams(::DeMarker_SignalOpenMethod, ::DeMarker_SignalOpenFilterMethod, ::DeMarker_SignalOpenLevel,
                  ::DeMarker_SignalOpenBoostMethod, ::DeMarker_SignalCloseMethod, ::DeMarker_SignalCloseFilter,
                  ::DeMarker_SignalCloseLevel, ::DeMarker_PriceStopMethod, ::DeMarker_PriceStopLevel,
                  ::DeMarker_TickFilterMethod, ::DeMarker_MaxSpread, ::DeMarker_Shift) {
    Set(STRAT_PARAM_LS, DeMarker_LotSize);
    Set(STRAT_PARAM_OCL, DeMarker_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, DeMarker_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, DeMarker_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, DeMarker_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_DeMarker : public Strategy {
 public:
  Stg_DeMarker(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_DeMarker *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    Indi_DeMarker_Params_Defaults indi_demarker_defaults;
    DeMarkerParams _indi_params(indi_demarker_defaults, _tf);
    Stg_DeMarker_Params_Defaults stg_demarker_defaults;
    StgParams _stg_params(stg_demarker_defaults);
#ifdef __config__
    SetParamsByTf<DeMarkerParams>(_indi_params, _tf, indi_demarker_m1, indi_demarker_m5, indi_demarker_m15,
                                  indi_demarker_m30, indi_demarker_h1, indi_demarker_h4, indi_demarker_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_demarker_m1, stg_demarker_m5, stg_demarker_m15, stg_demarker_m30,
                             stg_demarker_h1, stg_demarker_h4, stg_demarker_h8);
#endif
    // Initialize indicator.
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_DeMarker(_stg_params, _tparams, _cparams, "DeMarker");
    _strat.SetIndicator(new Indi_DeMarker(_indi_params));
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
    Indi_DeMarker *_indi = GetIndicator();
    Chart *_chart = (Chart *)_indi;
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi[_shift][0] < 0.5 - _level;
        _result &= _indi.IsIncreasing(2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi[_shift][0] > 0.5 + _level;
        _result &= _indi.IsDecreasing(2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
