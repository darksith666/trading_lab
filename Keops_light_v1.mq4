/*      .=====================================.
       /              Keops Light              \
      |               by Edorenta               |
       \          Range Pyramidal Bot          /
        '====================================='
*/

#property copyright     "Paul de Renty (Edorenta @ ForexFactory.com)"
#property link          "edorenta@gmail.com (mp me on FF rather than by email)"
#property description   "Keops Light : Simplistic range incremental trading"
#property version       "1.0"
string version =        "1.0";
#property strict
#include <stdlib.mqh>

/*    .-----------------------.
      |    EXTERNAL INPUTS    |
      '-----------------------'
*/

extern string __3__ = "---------------------------------------------------------------------------------------------------------"; //[------------   STEP SETTINGS   ------------]

enum stpm   {fixed_step                      //Fixed Step (Points) [CS0]
            ,pair_pct_step                   //Pair /10000 Step [CS1]
            ,hilo_pct_step                   //High-Low % Step [CS2]         
            ,atr_step                        //Pure ATR Step [CS3]
            ,sdev_step                       //Pure Standard Dev Step [CS4]
            ,hybrid_step                     //Above Hybrid Step [CS5]
            ,true_spread                     //Real Spread [CS6]
            ,};
extern stpm step_mode = hybrid_step;         //Step Mode [Custom Step]

extern double step_pts = 20;                 //Step in Points [CS0]
extern double step_pct = 8;                  //Relative Step /10000 [CS1]
extern int hilo_p = 50;                      //High/Low Lookback [CS2]
extern double hilo_xtor = 0.33;              //Step as HiLo% [CS2]
extern int atr_p = 10;                       //ATR Lookback [CS3]
extern int sdev_p = 20;                      //SDEV Lookback [CS4]
extern double atr_x = 1;                     //Vol Step Width Multiplier [CS3-4-5]
extern double step_x2 = 1.02;                //Step Width Increase Factor [CS3-4-5]
extern double spread_x = 5;                  //True Spread Factor [CS6]

extern string __4__ = "---------------------------------------------------------------------------------------------------------"; //[------------   TARGET SETTINGS   ------------]

extern double tp_evol_xtor = 1.005;          //TP/Step Increase Factor (1 = Static)

enum tgtm   {fixed_m_tgt                     //Fixed (€/$) [CT0]
            ,fixed_pct_tgt                   //Fixed K%(on init) [CT1]
            ,dynamic_pct_tqt                 //Dynamic K% [CT2]
            ,};     
extern tgtm tgt_mode = dynamic_pct_tqt;      //Target Calculation Mode [Custom Target]
enum bem    {use_be_target                   //TP at Breakeven + Target
            ,use_average                     //TP at average Target/BE
            ,use_be                          //TP at Breakeven
            ,no_be                           //Classic TP
            ,};
extern bem breakeven_mode = use_average;          //B-E Min Profit Lock-in

extern double b_money = 1.5;                 //Base Money [Static Money (€/$)]
extern double b_money_risk = 0.03;           //Base Risk Money [Dynamic Money %K]

extern string __5__ = "---------------------------------------------------------------------------------------------------------"; //[------------   SCALE SETTINGS   ------------]

enum mm     {classic                         //Classic [MM0]
            ,mart                            //Martingale [MM1]
            ,scale                           //Scale-in Loss [MM2]
            ,};
extern mm mm_mode = mart;                    //Money Management Mode [Custom MM]

extern int mm_step = 1;                      //MM Trades Step
extern int mm_step_start = 3;                //MM Step Starting Trade
extern int mm_step_end = 50;                 //MM Step Ending Trade
extern double xtor = 1.66;                   //Martingale Target Multiplier [MM1]
extern double increment = 100;               //Scaler Target Increment % [MM2]

extern string __6__ = "---------------------------------------------------------------------------------------------------------"; //[------------   RISK SETTINGS   ------------]

extern double max_xtor = 60;                 //Max Multiplier [MM1]
extern double max_increment = 1000;          //Max Increment % [MM2]

extern int max_trades = 10;                   //Max Recovery Trades
extern bool use_hard_acc_stop = false;       //Enable Hard Account Stops
extern double emergency_acc_stop_pc = 25;    //Hard Account Drawdown Stop (%K)
extern double emergency_acc_stop = 500;      //Hard Account Drawdown Stop (€/$)
extern bool use_hard_ea_stop = true;         //Enable Hard EA Stops
extern double emergency_ea_stop_pc = 25;     //Hard EA Drawdown Stop (%K)
extern double emergency_ea_stop = 500;       //Hard EA Drawdown Stop (€/$)

extern bool negative_margin = false;         //Allow Negative Margin

extern double daily_profit_pc = 50;           //Stop After Daily Profit (%K)
extern double daily_loss_pc = 50;             //Stop After Daily Loss (%K)

extern string __7__ = "---------------------------------------------------------------------------------------------------------"; //[------------   BROKER & TIME SETTINGS   ------------]

extern bool ECN_orders = false;              //ECN Order Execution
extern int max_spread = 30;                  //Max Spread (Points)
extern bool use_max_spread_in_cycle = false; //Enable Max Spread In Cycle
extern int magic = 101;                      //Magic Number
extern int slippage = 15;                    //Execution Slippage

extern int nb_pass = 10;                            //Pass numbers for Random Entries

extern string _____ = "COMING SOON";

//Data count variables initialization

      double max_acc_dd = 0;
      double max_acc_dd_pc = 0;
      double max_dd = 0;
      double max_dd_pc = 0;
      double max_acc_runup = 0;
      double max_acc_runup_pc = 0;
      double max_runup = 0;
      double max_runup_pc = 0;
      int max_chain_win = 0;
      int max_chain_loss = 0;
      int max_histo_spread = 0;
      double target_long = 0;
      double target_short = 0;
      bool ongoing_long = false;
      bool ongoing_short = false;
      bool enter_long, enter_short;
      double starting_equity = 0;
      int current_bar = 0;
      bool trade_on_button = true;
         
//        o-----------------------o
//        |    ON INIT TRIGGERS   |
//        o-----------------------o

int OnInit(){
   
   starting_equity = AccountEquity();
   return(INIT_SUCCEEDED);
}

//        o-----------------------o
//        |   ON DEINIT TRIGGERS  |
//        o-----------------------o


int OnDeinit(){
   return(0);
}

//        o-----------------------o
//        |    ONTICK TRIGGERS    |
//        o-----------------------o

void OnTick() {

    check_if_close();

    if (current_bar != Bars) {
        if (trading_authorized() == true) {
            int nb_longs = trades_info(1);
            int nb_shorts = trades_info(2);
            int nb_trades = nb_longs + nb_shorts;

            if (nb_longs == 0) {
                first_trade(1);
            }

            if (nb_shorts == 0) {
                first_trade(2);
            }

            if (nb_longs != 0 && enter_long == true) {
                if (ECN_orders == true) {
                    spam_long_ECN();
                } else {
                    spam_long();
                }
            }

            if (nb_shorts != 0 && enter_short == true) {
                if (ECN_orders == true) {
                    spam_short_ECN();
                } else {
                    spam_short();
                }
            }
        }
    }
    //   Comment("Trading Authorized : ", trading_authorized());
    // Comment(pyramid);
}

//        o-----------------------o
//        |    EMERGENCY CUTS     |
//        o-----------------------o

void check_if_close() {

    if (negative_margin == false && AccountFreeMargin() <= 0) close_all();

    if (use_hard_acc_stop) {
        if ((AccountEquity() - AccountBalance()) / AccountBalance() < -emergency_acc_stop_pc / 100) close_all();
        if ((AccountEquity() - AccountBalance()) < -emergency_acc_stop) close_all();
    }
    if (use_hard_ea_stop) {
        if ((data_counter(15) / AccountBalance()) < -emergency_ea_stop_pc / 100) {
            close_all();
        }
        if ((data_counter(15)) < -emergency_ea_stop) {
            close_all();
        }
    }
}

void close_all() {

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) {
                OrderClose(OrderTicket(), OrderLots(), Bid, slippage, Turquoise);
            }
            if (OrderType() == OP_SELL) {
                OrderClose(OrderTicket(), OrderLots(), Ask, slippage, Magenta);
            }
        }
    }
}
void close_long() {

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) {
                OrderClose(OrderTicket(), OrderLots(), Bid, slippage, Turquoise);
            }
        }
    }
}
void close_short() {

        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
                if (OrderType() == OP_SELL) {
                    OrderClose(OrderTicket(), OrderLots(), Ask, slippage, Magenta);
                }
            }
        }
    }
    //        o-----------------------o
    //        |      FIRST TRADE      |
    //        o-----------------------o

void first_trade(int key) {

    bool enter_long_2 = false, enter_short_2 = false;
    double last, spread;

    if (ECN_orders == true) {
        BUY_ECN();
    } else {
        BUY();
    }
    if (ECN_orders == true) {
        SELL_ECN();
    } else {
        SELL();
    }
}

void BUY() {
    int ticket;
    double TP = NormalizeDouble(TP_long(), Digits);
    ticket = OrderSend(Symbol(), OP_BUY, lotsize_long(), Ask, slippage, 0, Ask + TP, "Keops " + DoubleToStr(lotsize_long(), 2) + " on " + Symbol(), magic, 0, Turquoise);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
}

void BUY_ECN() {

    int ticket;
    double TP = NormalizeDouble(TP_long(), Digits);
    ticket = OrderSend(Symbol(), OP_BUY, lotsize_long(), Ask, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_long(), 2) + " on " + Symbol(), magic, 0, Turquoise);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
    for (int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
            OrderModify(OrderTicket(), OrderOpenPrice(), 0, Ask + TP, 0, Turquoise);
        }
    }
    //   if(show_gui){calc_target();}
}

void SELL() {
    int ticket;
    double TP = NormalizeDouble(TP_short(), Digits);
    ticket = OrderSend(Symbol(), OP_SELL, lotsize_short(), Bid, slippage, 0, Bid - TP, "Keops " + DoubleToStr(lotsize_short(), 2) + " on " + Symbol(), magic, 0, Magenta);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
}
void SELL_ECN() {
    int ticket;
    double TP = NormalizeDouble(TP_short(), Digits);
    ticket = OrderSend(Symbol(), OP_SELL, lotsize_short(), Bid, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_short(), 2) + " on " + Symbol(), magic, 0, Magenta);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
    for (int i = 0; i < OrdersTotal(); i++) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
            OrderModify(OrderTicket(), OrderOpenPrice(), 0, Bid - TP, 0, Magenta);
        }
    }
    //   if(show_gui){calc_target();}
}

//        o-----------------------o
//        |   SPAM OTHER TRADES   |
//        o-----------------------o

void spam_long_ECN() {
    if (trades_info(3) < max_trades) {
        if (Bid <= (trades_info(4) - STEP())) {
            BUY_ECN();
        }
    }
}

void spam_long() {
    double TP = NormalizeDouble(TP_long(), Digits);
    if (trades_info(3) < max_trades) {
        if (Bid <= (trades_info(4) - STEP())) {
            int ticket = OrderSend(Symbol(), OP_BUY, lotsize_long(), Ask, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_long(), 2) + " on " + Symbol(), magic, 0, Turquoise);
            if (ticket < 0) {
                Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
            }
            for (int i = 0; i < OrdersTotal(); i++) {
                OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
                if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                    OrderModify(OrderTicket(), OrderOpenPrice(), 0, Ask + TP, 0, Turquoise);
                }
            }
        }
    }
}

void spam_short_ECN() {
    if (trades_info(3) < max_trades) {
        if (Ask >= (trades_info(7) + STEP())) {
            SELL_ECN();
        }
    }
}

void spam_short() {
    double TP = NormalizeDouble(TP_short(), Digits);
    if (trades_info(3) < max_trades) {
        if (Ask >= (trades_info(7) + STEP())) {
            int ticket = OrderSend(Symbol(), OP_SELL, lotsize_short(), Bid, slippage, 0, 0, "Keops " + DoubleToStr(lotsize_short(), 2) + " on " + Symbol(), magic, 0, Magenta);
            if (ticket < 0) {
                Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
            }
            for (int i = 0; i < OrdersTotal(); i++) {
                OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
                if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                    OrderModify(OrderTicket(), OrderOpenPrice(), 0, Bid - TP, 0, Magenta);
                }
            }
        }
    }
}

//        o----------------------o
//        | S/L COUNTER FUNCTION |
//        o----------------------o

double trades_info(int key) {

    double nb_longs = 0, nb_shorts = 0, nb_trades = 0, nb = 0;
    double buy_min = 0, buy_max = 0, sell_min = 0, sell_max = 0;

    for (int i = OrdersTotal(); i >= 0; i--) {
        OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) {
                nb_longs++;
                if (OrderOpenPrice() < buy_min || buy_min == 0) {
                    buy_min = OrderOpenPrice();
                }
                if (OrderOpenPrice() > buy_max || buy_min == 0) {
                    buy_max = OrderOpenPrice();
                }
            }
            if (OrderType() == OP_SELL) {
                nb_shorts++;
                if (OrderOpenPrice() > sell_max || sell_max == 0) {
                    sell_max = OrderOpenPrice();
                }
                if (OrderOpenPrice() < sell_min || sell_min == 0) {
                    sell_min = OrderOpenPrice();
                }
            }
        }
    }

    nb_trades = nb_longs + nb_shorts;

    switch (key) {
    case 1:
        nb = nb_longs;
        break;
    case 2:
        nb = nb_shorts;
        break;
    case 3:
        nb = nb_trades;
        break;
    case 4:
        nb = buy_min;
        break;
    case 5:
        nb = buy_max;
        break;
    case 6:
        nb = sell_min;
        break;
    case 7:
        nb = sell_max;
        break;
    }
    return (nb);
}

//        o----------------------o
//        | TARGET CALC FUNCTION |
//        o----------------------o

double STEP() {

    double steplvl, pair1, hi_px, lo_px, hilo1, atr1, atr2, atr3, sdev1, sdev2, sdev3;
    int hi_shift, lo_shift;
    double point = 0.00001;

    double freezelvl = MarketInfo(Symbol(), MODE_FREEZELEVEL) * Point;
    double spread = MarketInfo(Symbol(), MODE_SPREAD) * Point;

    if (step_mode == true_spread) steplvl = spread_x * (Ask - Bid);
    if (step_mode == fixed_step) steplvl = step_pts * Point;
    if (step_mode == pair_pct_step || step_mode == hybrid_step) {
        double pair1 = ((step_pct * Bid)) * point;
        steplvl = pair1;
    }
    if (step_mode == hilo_pct_step || step_mode == hybrid_step) {
        hi_shift = iHighest(Symbol(), 0, MODE_HIGH, hilo_p, 0);
        hi_px = iHigh(Symbol(), 0, hi_shift);
        lo_shift = iLowest(Symbol(), 0, MODE_LOW, hilo_p, 0);
        lo_px = iLow(Symbol(), 0, lo_shift);
        hilo1 = (hi_px - lo_px) * hilo_xtor;
        steplvl = NormalizeDouble(hilo1, Digits);
    }
    if (step_mode == atr_step || step_mode == hybrid_step) {
        atr1 = iATR(Symbol(), 0, atr_p, 0);
        atr2 = iATR(Symbol(), 0, 2 * atr_p, 0);
        atr3 = ((atr1 + atr2) / 2) * atr_x;
        steplvl = NormalizeDouble(atr3, Digits);
    }
    if (step_mode == sdev_step || step_mode == hybrid_step) {
        sdev1 = iStdDev(Symbol(), 0, sdev_p, 0, MODE_LWMA, PRICE_CLOSE, 0);
        sdev2 = iStdDev(Symbol(), 0, sdev_p * 2, 0, MODE_LWMA, PRICE_CLOSE, 0);
        sdev3 = ((sdev1 + sdev2) / 2) * atr_x;
        steplvl = NormalizeDouble(sdev3, Digits);
    }
    if (step_mode == hybrid_step) {
        steplvl = NormalizeDouble((hilo1 + 2 * atr3 + 2 * sdev3 * 2 + pair1) / 8, Digits);
    }

    steplvl = steplvl * (pow(step_x2, trades_info(3)));

    if (spread >= (steplvl / 2)) steplvl = spread * 2;
    if (freezelvl >= steplvl) steplvl = freezelvl;

    return (steplvl);
}

//        o----------------------o
//        | TARGET CALC FUNCTION |
//        o----------------------o
double breakeven_long() {

    double avg_px, lots_long, lots_short, price_long, price_short, weight_long, weight_short;

    if (trades_info(3) != 0) {
        lots_long = data_counter(21);
        price_long = data_counter(19);

        if (lots_long != 0) {
            avg_px = NormalizeDouble(price_long / lots_long, Digits); //avg buying price
        }
    }
    return (avg_px);
}

double breakeven_short() {

    double avg_px, lots_long, lots_short, price_long, price_short, weight_long, weight_short;

    if (trades_info(3) != 0) {
        lots_short = data_counter(22);
        price_short = data_counter(20);

        if (lots_short != 0) {
            avg_px = NormalizeDouble(price_short / lots_short, Digits); //avg selling price
        }
    }
    return (avg_px);
}

double TP_long() {

    double BE, tplvl;
    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
    double spread = Ask - Bid;
    int nb_longs;
    int nb_shorts;

    if (trades_info(1) != 0) {
        nb_longs = trades_info(1);
    }
    if (trades_info(2) != 0) {
        nb_shorts = trades_info(2);
    }

    double nb_trades = trades_info(3);
    double tp_offset = NormalizeDouble(STEP() * pow(tp_evol_xtor, nb_trades), Digits);

    BE = tp_offset;

    if (trades_info(1) != 0) {
        switch (breakeven_mode) {
        case use_average:
            BE = (2 * MathAbs(breakeven_long() - Ask) + tp_offset + spread) / 3;
            break;
        case use_be:
            BE = (breakeven_long() - Ask) + spread;
            break;
        case use_be_target:
            BE = MathAbs(breakeven_long() - Ask) + (tp_offset / nb_longs);
            break;
        case no_be:
            BE = (tp_offset);
            break;
        }
    }
    tplvl = BE;

    if (tplvl < stoplvl) {
        tplvl = stoplvl;
    }

    return (tplvl);
}

double TP_short() {

    double BE, tplvl;
    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
    double spread = Ask - Bid;
    int nb_longs;
    int nb_shorts;

    if (trades_info(1) != 0) {
        nb_longs = trades_info(1);
    }
    if (trades_info(2) != 0) {
        nb_shorts = trades_info(2);
    }

    double nb_trades = trades_info(3);
    double tp_offset = NormalizeDouble(STEP() * pow(tp_evol_xtor, nb_trades), Digits);

    BE = tp_offset;

    if (trades_info(2) != 0) {
        switch (breakeven_mode) {
        case use_average:
            BE = (2 * MathAbs(Bid - breakeven_short()) + tp_offset + spread) / 3;
            break;
        case use_be:
            BE = (Bid - breakeven_short()) + spread;
            break;
        case use_be_target:
            BE = MathAbs(Bid - breakeven_short()) + (tp_offset / nb_shorts);
            break;
        case no_be:
            BE = (tp_offset);
            break;
        }
    }
    tplvl = BE;

    if (tplvl < stoplvl) {
        tplvl = stoplvl;
    }

    return (tplvl);
}

//        o----------------------o
//        |  LOTS CALC FUNCTION  |
//        o----------------------o

double lotsize_long() {

    int nb_longs = trades_info(1);

    int trade_step = nb_longs;

    if (mm_step > 1) {
        if (nb_longs >= mm_step_start && nb_longs <= mm_step_end) {
            trade_step = MathCeil(nb_longs / mm_step);
        }
    }

    double temp_lots, risk_to_SL, mlots = 0;
    double equity = AccountEquity();
    double margin = AccountFreeMargin();
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double pip_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    int leverage = AccountLeverage();
    double TP = STEP() * pow(tp_evol_xtor, nb_longs);

    risk_to_SL = TP * (pip_value / pip_size);

    if (TP != 0) {
        switch (tgt_mode) {
        case fixed_m_tgt:
            temp_lots = NormalizeDouble(b_money / (risk_to_SL), 2);
            break;
        case fixed_pct_tgt:
            temp_lots = NormalizeDouble((b_money_risk * starting_equity) / (risk_to_SL * 1000), 2);
            break;
        case dynamic_pct_tqt:
            temp_lots = NormalizeDouble((b_money_risk * equity) / (risk_to_SL * 1000), 2);
            break;
        }
    }

    if (temp_lots < minlot) temp_lots = minlot;
    if (temp_lots > maxlot) temp_lots = maxlot;

    switch (mm_mode) {
    case mart:
        mlots = NormalizeDouble(temp_lots * (MathPow(xtor, (trade_step))), 2);
        if (mlots > temp_lots * max_xtor) mlots = NormalizeDouble(temp_lots * max_xtor, 2);
        break;
    case scale:
        mlots = temp_lots + ((increment / 100) * trade_step) * temp_lots;
        if (mlots > temp_lots * (1 + (max_increment / 100))) mlots = temp_lots * (1 + (max_increment / 100));
        break;
    case classic:
        mlots = temp_lots;
        break;
    }

    if (mlots < minlot) mlots = minlot;
    if (mlots > maxlot) mlots = maxlot;

    return (mlots);
}

double lotsize_short() {

    int nb_shorts = trades_info(2);

    int trade_step = nb_shorts;

    if (mm_step > 1) {
        if (nb_shorts >= mm_step_start && nb_shorts <= mm_step_end) {
            trade_step = MathCeil(nb_shorts / mm_step);
        }
    }

    double temp_lots, risk_to_SL, mlots = 0;
    double equity = AccountEquity();
    double margin = AccountFreeMargin();
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double pip_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    int leverage = AccountLeverage();
    double TP = STEP() * pow(tp_evol_xtor, nb_shorts);

    risk_to_SL = TP * (pip_value / pip_size);

    if (TP != 0) {
        switch (tgt_mode) {
        case fixed_m_tgt:
            temp_lots = NormalizeDouble(b_money / (risk_to_SL), 2);
            break;
        case fixed_pct_tgt:
            temp_lots = NormalizeDouble((b_money_risk * starting_equity) / (risk_to_SL * 1000), 2);
            break;
        case dynamic_pct_tqt:
            temp_lots = NormalizeDouble((b_money_risk * equity) / (risk_to_SL * 1000), 2);
            break;
        }
    }

    if (temp_lots < minlot) temp_lots = minlot;
    if (temp_lots > maxlot) temp_lots = maxlot;

    switch (mm_mode) {
    case mart:
        mlots = NormalizeDouble(temp_lots * (MathPow(xtor, (trade_step))), 2);
        if (mlots > temp_lots * max_xtor) mlots = NormalizeDouble(temp_lots * max_xtor, 2);
        break;
    case scale:
        mlots = temp_lots + ((increment / 100) * trade_step) * temp_lots;
        if (mlots > temp_lots * (1 + (max_increment / 100))) mlots = temp_lots * (1 + (max_increment / 100));
        break;
    case classic:
        mlots = temp_lots;
        break;
    }

    if (mlots < minlot) mlots = minlot;
    if (mlots > maxlot) mlots = maxlot;

    return (mlots);
}

void calc_target() {

    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double pip_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    double profit_long = data_counter(24);
    double profit_short = data_counter(25);
    double TP_value_long = TP_long() * (pip_value / pip_size);
    double TP_value_short = TP_short() * (pip_value / pip_size);
    double lots_long = data_counter(21);
    double lots_short = data_counter(22);
    double gross_target_long = profit_long + lots_long * TP_value_long;
    double gross_target_short = profit_short + lots_short * TP_value_short;

    target_long = gross_target_long;
    target_short = gross_target_short;

}

//        o----------------------o
//        | TRADE FILTR FUNCTION |
//        o----------------------o

bool trading_authorized() {

    int trade_condition = 1;

    if (trade_today() == false) trade_condition = 0;
    if (spread_okay() == false) trade_condition = 0;
    if (filter_off() == false) trade_condition = 0;
    if (trade_on_button == false) trade_condition = 0;

    if (trade_condition == 1) {
        return (true);
    } else {
        return (false);
    }
}

bool spread_okay() {
    bool spread_filter_off = true;
    if (use_max_spread_in_cycle == true && trades_info(3) > 0 || trades_info(3) == 0) {
        if (MarketInfo(Symbol(), MODE_SPREAD) >= max_spread) {
            spread_filter_off = false;
        }
    }
    return (spread_filter_off);
}

bool filter_off() {

    bool filter_off = true;

    return (filter_off);
}

bool trade_today() {

    double profit_today = Earnings(0);
    double profit_pct_today = profit_today / (AccountEquity() - profit_today);
    //   Comment("Profit today : " + profit_today + " % : " + profit_pct_today);

    if (profit_today == 0 || profit_pct_today <= daily_profit_pc / 100 || profit_pct_today >= daily_loss_pc / 100) {
        return (true);
    } else {
        return (false);
    }
}

double Earnings(int shift) {
    double aggregated_profit = 0;
    for (int position = 0; position < OrdersHistoryTotal(); position++) {
        if (!(OrderSelect(position, SELECT_BY_POS, MODE_HISTORY))) break;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic)
            if (OrderCloseTime() >= iTime(Symbol(), PERIOD_D1, shift) && OrderCloseTime() < iTime(Symbol(), PERIOD_D1, shift) + 86400) aggregated_profit = aggregated_profit + OrderProfit() + OrderCommission() + OrderSwap();
    }
    return (aggregated_profit);
}

//        o----------------------o
//        |    GET OTHER DATA    |
//        o----------------------o

double data_counter(int key) {

    double count_tot = 0, balance = AccountBalance(), equity = AccountEquity();
    double drawdown = 0, runup = 0, lots = 0, profit = 0;

    switch (key) {

    case (1): //All time wins counter
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                count_tot++;
            }
        }
        break;

    case (2): //All time loss counter
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                count_tot++;
            }
        }
        break;

    case (3): //All time profit
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
            count_tot = profit;
        }
        break;

    case (4): //All time lots
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                lots = lots + OrderLots();
            }
            count_tot = lots;
        }
        break;

    case (5): //Chain Loss
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                count_tot++;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                count_tot = 0;
            }
            //         if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit()<0 && count_tot>max_risk_trades) count_tot = 0;
        }
        break;

    case (6): //Chain Win
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                count_tot++;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                count_tot = 0;
            }
            //         if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit()>0 && count_tot>max_risk_trades) count_tot = 0;
        }
        break;

    case (7): //Chart Drawdown % (if equity < balance)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit > 0) drawdown = 0;
        else drawdown = NormalizeDouble((profit / balance) * 100, 2);
        count_tot = drawdown;
        break;

    case (8): //Acc Drawdown % (if equity < balance)
        if (equity >= balance) drawdown = 0;
        else drawdown = NormalizeDouble(((equity - balance) * 100) / balance, 2);
        count_tot = drawdown;
        break;

    case (9): //Chart dd money (if equity < balance)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit >= 0) drawdown = 0;
        else drawdown = profit;
        count_tot = drawdown;
        break;

    case (10): //Acc dd money (if equiy < balance)
        if (equity >= balance) drawdown = 0;
        else drawdown = equity - balance;
        count_tot = drawdown;
        break;

    case (11): //Chart Runup %
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit < 0) runup = 0;
        else runup = NormalizeDouble((profit / balance) * 100, 2);
        count_tot = runup;
        break;

    case (12): //Acc Runup %
        if (equity < balance) runup = 0;
        else runup = NormalizeDouble(((equity - balance) * 100) / balance, 2);
        count_tot = runup;
        break;

    case (13): //Chart runup money
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        if (profit < 0) runup = 0;
        else runup = profit;
        count_tot = runup;
        break;

    case (14): //Acc runup money
        if (equity < balance) runup = 0;
        else runup = equity - balance;
        count_tot = runup;
        break;

    case (15): //Current profit here
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (16): //Current profit acc
        count_tot = AccountProfit();
        break;

    case (17): //Gross profits
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (18): //Gross loss
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (19): //(average buying price longs)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                count_tot = count_tot + OrderLots() * (OrderOpenPrice());
            }
        }
        break;

    case (20): //(average buying price shorts)
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                count_tot = count_tot + OrderLots() * (OrderOpenPrice());
            }
        }
        break;

    case (21): //Current lots long
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;

    case (22): //Current lots short
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;

    case (23): //Current lots all
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;

    case (24): //Current profit here Long
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;

    case (25): //Current profit here Short
        for (int i = 0; i <= OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                profit = profit + OrderProfit() + OrderCommission() + OrderSwap();
            }
        }
        count_tot = profit;
        break;
    }
    return (count_tot);
}