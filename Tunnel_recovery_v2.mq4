/*      .=====================================.
       /            Tunnel Recovery            \
      |               by Edorenta               |
       \       Range Tunnel Pyramidal Bot      /
        '====================================='
*/

#property copyright     "Paul de Renty (Edorenta @ ForexFactory.com)"
#property link          "edorenta@gmail.com (mp me on FF rather than by email)"
#property description   "Mashup : Tunnel Breakout + Recovery Zone"
#property version       "0.1"
string version =        "0.1";
#property strict
#include <stdlib.mqh>

//        o-----------------------o
//        |  externAL VARIABLES   |
//        o-----------------------o

extern string __0__ = "---------------------------------------------------------------------------------------------------------"; //[------------   GENERAL SETTINGS   ------------]

extern bool one_trade_per_bar = true;        //Only One Trade Per Bar
extern bool use_long = true;                 //Enable Longs
extern bool use_short = true;                //Enable Shorts
enum hi {HH  //Highest High
        ,HL  //Highest Low
        ,HC  //Highest Close
        ,HO  //Highest Open
};

enum lo {LH  //Lowest High
        ,LL  //Lowest Low
        ,LC  //Lowest Close
        ,LO  //Lowest Open
};

extern string __1__ = "---------------------------------------------------------------------------------------------------------"; //[------------   TUNNEL SETTINGS   ------------]

extern int hilo_tf = 40;                      //High / Low Horizon
extern int hilo_tf_shift = 20;                //Old Channel Shift

extern hi hi_mode = HH;                       //High Mode
extern lo lo_mode = LL;                       //Low Mode

extern int tunnel_width_offset = 2;                      //Tunnel Width Offset +/- (cPips)
extern int tunnel_max_width = 15;                        //Tunnel Max Width (cPips)
extern int tunnel_min_width = 6;                         //Tunnel Min Width (cPips)
extern bool one_side_lockin = true;                      //Build Tunnel from 1 side Lockin

extern bool use_pending_setup = false;      //Use Pending Orders (First Entry)
extern int expiration_mins = 720;           //Exp. Mins for Pending Orders
       bool rev_signal = false;             //Reverse Signal (mean reversion)
       int max_longs = 1;                   //Max Long Trades
       int max_shorts = 1;                  //Max Short Trades
       
extern string __3__ = "---------------------------------------------------------------------------------------------------------"; //[------------   TP SETTINGS   ------------]

extern double tp_evol_xtor = 1.025;          //TP Increase Factor (1 = Static)
extern int tp_offset = 2;                    //TP Offset +/- (cPips)


extern string __4__ = "---------------------------------------------------------------------------------------------------------"; //[------------   TARGET SETTINGS   ------------]

enum tgtm   {fixed_m_tgt                     //Fixed (€/$) [CT0]
            ,fixed_pct_tgt                   //Fixed K%(on init) [CT1]
            ,dynamic_pct_tqt                 //Dynamic K% [CT2]
            ,};     
extern tgtm tgt_mode = dynamic_pct_tqt;      //Target Calculation Mode [Custom Target]
enum bem    {use_be_target                   //TP at Breakeven + Target
            ,use_be                          //TP at Breakeven
            ,no_be                           //Classic TP
            ,};

extern double b_money = 1;                   //Base Money [Static Money (€/$)]
extern double b_money_risk = 0.05;           //Base Risk Money [Dynamic Money %K]

extern string __5__ = "---------------------------------------------------------------------------------------------------------"; //[------------   SCALE SETTINGS   ------------]

enum mm     {classic                         //Classic [MM0]
            ,mart                            //Martingale [MM1]
            ,scale                           //Scale-in Loss [MM2]
            ,};
extern mm mm_mode = mart;                    //Money Management Mode [Custom MM]

extern double xtor = 1.8;                    //Martingale Target Multiplier [MM1]
extern double increment = 100;               //Scaler Target Increment % [MM2]

extern string __6__ = "---------------------------------------------------------------------------------------------------------"; //[------------   RISK SETTINGS   ------------]

extern double max_xtor = 60;                 //Max Multiplier [MM1]
extern double max_increment = 1000;          //Max Increment % [MM2]

extern int max_risk_trades = 9;              //Max Recovery Trades
extern bool use_hard_acc_stop = false;       //Enable Hard Account Stops
extern double emergency_acc_stop_pc = 25;    //Hard Account Drawdown Stop (%K)
extern double emergency_acc_stop = 500;      //Hard Account Drawdown Stop (€/$)
extern bool use_hard_ea_stop = true;         //Enable Hard EA Stops
extern double emergency_ea_stop_pc = 25;     //Hard EA Drawdown Stop (%K)
extern double emergency_ea_stop = 500;       //Hard EA Drawdown Stop (€/$)

extern bool negative_margin = false;         //Allow Negative Margin

extern double daily_profit_pc = 5;           //Stop After Daily Profit (%K)
extern double daily_loss_pc = 5;             //Stop After Daily Loss (%K)

extern string __7__ = "---------------------------------------------------------------------------------------------------------"; //[------------   BROKER SETTINGS   ------------]

extern int max_spread = 30;                  //Max Spread (Points)
       bool use_max_spread_in_cycle = false; //Enable Max Spread In Cycle
extern int magic = 101;                      //Magic Number
extern int slippage = 15;                    //Execution Slippage

extern string __8__ = "---------------------------------------------------------------------------------------------------------"; //[------------   GUI SETTINGS   ------------]

extern bool use_close_button = true;                //Show Close All Button
extern bool show_tunnel = true;                     //Plot The Tunnel
extern bool show_hilo = true;                       //Plot The Highs & Lows
extern bool show_gui = true;                        //Show The EA GUI
extern color color1 = LightGray;                    //EA's name color
extern color color2 = DarkOrange;                   //EA's balance & info color
extern color color3 = Turquoise;                    //EA's profit color
extern color color4 = Magenta;                      //EA's loss color

       int hi_shift, lo_shift, phi_shift, plo_shift, mid_shift;
static double hi_px, lo_px, mid_px, phi_px, plo_px;
static double tunnel_top_px, tunnel_bot_px, tunnel_mid_px;

       string tunnel_top_name = "Tunnel Top";      //Tunnel Top Name
       string tunnel_bot_name = "Tunnel Bot";      //Tunnel Bot Name
       string tunnel_mid_name = "Pivot";           //Tunnel Pivot Name

       string hi_name = "Channel Top";      //Channel Top Name
       string lo_name = "Channel Bot";      //Channel Bot Name
       string phi_name = "Channel Old Top"; //Channel Old Top Name
       string plo_name = "Channel Old Bot"; //Channel Old Bot Name

extern color tunnel_top_clr = Turquoise;            //Tunnel Top Color
extern color tunnel_bot_clr = Magenta;              //Tunnel Bot Color
extern ENUM_LINE_STYLE style_2 = STYLE_SOLID;       //Tunnel Style
extern int width_2 = 3;                             //Tunnel Levels width
       
       color hi_clr = LightGray;            //Channel Top Color
       color lo_clr = LightGray;            //Channel Bot Color
       color phi_clr = DarkGray;            //Channel Old Top Color
       color plo_clr = DarkGray;            //Channel Old Bot Color
       color mid_clr = DarkOrange;          //Channel Pivot Color
       
       ENUM_LINE_STYLE style_1 = STYLE_DOT; //Channel Style
       int width_1 = 1;                     //Channel Levels width
       bool back = true;                    //Levels in the Background
       bool selection = true;               //Levels Selectable
       bool hidden = true;                  //Hidden in the Object list
       long chart_ID = 0;
       double starting_equity = 0;
       int current_bar = 0;
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
       
       string button1_name = "close_all_button";
       string button1_txt = "CLOSE ALL"; //(magic " + IntegerToString(magic) + ")";

//        o-----------------------o
//        |    ON INIT TRIGGERS   |
//        o-----------------------o
int OnInit() {

    starting_equity = AccountEquity();
    if (show_gui) {
        HUD();
    }
    EA_name();

    if (use_close_button == true) {
        ObjectCreate(0, button1_name, OBJ_BUTTON, 0, 0, 0);
        ObjectSetInteger(0, button1_name, OBJPROP_XDISTANCE, 290);
        ObjectSetInteger(0, button1_name, OBJPROP_YDISTANCE, 28);
        ObjectSetInteger(0, button1_name, OBJPROP_XSIZE, 140);
        ObjectSetInteger(0, button1_name, OBJPROP_YSIZE, 60);
        ObjectSetString(0, button1_name, OBJPROP_TEXT, button1_txt);
        ObjectSetInteger(0, button1_name, OBJPROP_COLOR, color4);
        ObjectSetInteger(0, button1_name, OBJPROP_BGCOLOR, Black);
        ObjectSetInteger(0, button1_name, OBJPROP_BORDER_COLOR, color4);
        ObjectSetInteger(0, button1_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, button1_name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, button1_name, OBJPROP_STATE, false);
        ObjectSetInteger(0, button1_name, OBJPROP_FONTSIZE, 15);
    }
    return (INIT_SUCCEEDED);
}

//        o-----------------------o
//        |    ONTICK TRIGGERS    |
//        o-----------------------o

void OnTick() {

    if (show_gui) {
        GUI();
    }

    check_if_close();

    if (current_bar != Bars) {
        //    if(trading_authorized()==true) {

        int nb_longs = trade_counter(5);
        int nb_shorts = trade_counter(6);
        int nb_total = nb_longs + nb_shorts;
        int longs_pending = trade_counter(1) + trade_counter(3);
        int shorts_pending = trade_counter(2) + trade_counter(4);
        int pending_total = longs_pending + shorts_pending;
        int last = (Ask + Bid) / 2;

        if (one_side_lockin == true) {
            if ((HiLo(1) == HiLo(2) || HiLo(3) == HiLo(4)) && nb_total == 0 && data_counter(5) == 0) { //New Tunnel, last trade was a reset
                set_tunnel();

                if (use_pending_setup && pending_total == 0) {
                    set_short(Tunnel(-1));
                    set_long(Tunnel(1));
                }
            }
            if (use_pending_setup == false && nb_total == 0) {
                if (Ask >= Tunnel(1) && Bid <= Tunnel(1)) {
                    BUY();
                };
                if (Ask >= Tunnel(-1) && Bid <= Tunnel(-1)) {
                    SELL();
                };
            }
        }

        if (one_side_lockin == false) {
            if (HiLo(1) == HiLo(2) && HiLo(3) == HiLo(4) && nb_total == 0 && data_counter(5) == 0) {
                set_tunnel();

                if (use_pending_setup && pending_total == 0) {
                    set_short(Tunnel(-1));
                    set_long(Tunnel(1));
                }
            }
            if (use_pending_setup == false && nb_total == 0) {
                if (Ask >= Tunnel(1) && Bid <= Tunnel(1)) {
                    BUY();
                };
                if (Ask >= Tunnel(-1) && Bid <= Tunnel(-1)) {
                    SELL();
                };
            }
        }
        if (nb_longs != 0 && Bid <= Tunnel(-1)) {
            close_long();
            SELL();
        }
        if (nb_shorts != 0 && Ask >= Tunnel(1)) {
            close_short();
            BUY();
        }

        if (pending_total == 1) {
            cancel_long();
            cancel_short();
        }
        //    }
        if (one_trade_per_bar == true) current_bar = Bars;
    }
    //   Comment(pyramid);
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

//        o-----------------------o
//        |     CHANNEL HiLo      |      //Horizontal lines
//        o-----------------------o

double HiLo(int key) {

    double px;

    switch (hi_mode) {
    case HH:
        hi_shift = iHighest(Symbol(), 0, MODE_HIGH, hilo_tf, 0);
        phi_shift = iHighest(Symbol(), 0, MODE_HIGH, hilo_tf, hilo_tf_shift);
        break;
    case HL:
        hi_shift = iHighest(Symbol(), 0, MODE_LOW, hilo_tf, 0);
        phi_shift = iHighest(Symbol(), 0, MODE_LOW, hilo_tf, hilo_tf_shift);
        break;
    case HC:
        hi_shift = iHighest(Symbol(), 0, MODE_CLOSE, hilo_tf, 0);
        phi_shift = iHighest(Symbol(), 0, MODE_CLOSE, hilo_tf, hilo_tf_shift);
        break;
    case HO:
        hi_shift = iHighest(Symbol(), 0, MODE_OPEN, hilo_tf, 0);
        phi_shift = iHighest(Symbol(), 0, MODE_OPEN, hilo_tf, hilo_tf_shift);
        break;
    }
    switch (lo_mode) {
    case LH:
        lo_shift = iLowest(Symbol(), 0, MODE_HIGH, hilo_tf, 0);
        plo_shift = iLowest(Symbol(), 0, MODE_HIGH, hilo_tf, hilo_tf_shift);
        break;
    case LL:
        lo_shift = iLowest(Symbol(), 0, MODE_LOW, hilo_tf, 0);
        plo_shift = iLowest(Symbol(), 0, MODE_LOW, hilo_tf, hilo_tf_shift);
        break;
    case LC:
        lo_shift = iLowest(Symbol(), 0, MODE_CLOSE, hilo_tf, 0);
        plo_shift = iLowest(Symbol(), 0, MODE_CLOSE, hilo_tf, hilo_tf_shift);
        break;
    case LO:
        lo_shift = iLowest(Symbol(), 0, MODE_OPEN, hilo_tf, 0);
        plo_shift = iLowest(Symbol(), 0, MODE_OPEN, hilo_tf, hilo_tf_shift);
        break;
    }
    if (hi_px != iHigh(Symbol(), 0, hi_shift)) {
        hi_px = iHigh(Symbol(), 0, hi_shift);
        if (show_hilo) {
            draw_top();
        }
    }

    if (phi_px != iHigh(Symbol(), 0, phi_shift)) {
        phi_px = iHigh(Symbol(), 0, phi_shift);
        if (show_hilo) {
            draw_ptop();
        }
    }
    if (lo_px != iLow(Symbol(), 0, lo_shift)) {
        lo_px = iLow(Symbol(), 0, lo_shift);
        if (show_hilo) {
            draw_bot();
        }
    }
    if (plo_px != iLow(Symbol(), 0, plo_shift)) {
        plo_px = iLow(Symbol(), 0, plo_shift);
        if (show_hilo) {
            draw_pbot();
        }
    }

    switch (key) {
    case 1:
        px = hi_px;
        break;
    case 2:
        px = phi_px;
        break;
    case 3:
        px = lo_px;
        break;
    case 4:
        px = plo_px;
        break;
    case 5:
        px = mid_px;
        break;
    }
    return (px);
}

void set_tunnel() {

    if (show_tunnel) {
        erase_tunnel_top();
        erase_tunnel_bot();
    }

    tunnel_top_px = HiLo(1);
    tunnel_bot_px = HiLo(3);
    tunnel_mid_px = (tunnel_top_px + tunnel_bot_px) / 2;

    if (show_tunnel) {
        draw_tunnel_top();
        draw_tunnel_bot();
        draw_tunnel_mid();
    }
}

//        o-----------------------o
//        |    TUNNEL DRAWING     |
//        o-----------------------o

bool draw_line(color clr, double px, string name) {

    ObjectDelete(chart_ID, name);
    ObjectCreate(chart_ID, name, OBJ_HLINE, 0, Time[0], px);
    ObjectSet(name, OBJPROP_COLOR, clr);
    ObjectSet(name, OBJPROP_WIDTH, 2);
    ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(chart_ID, name, OBJPROP_STYLE, style_1);
    ObjectSetInteger(chart_ID, name, OBJPROP_WIDTH, width_1);
    ObjectSetInteger(chart_ID, name, OBJPROP_BACK, back);
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, selection);
    ObjectSetInteger(chart_ID, name, OBJPROP_HIDDEN, hidden);
    WindowRedraw();

    return (true);
}

bool draw_line_tunnel(color clr, double px, string name) {

    ObjectDelete(chart_ID, name);
    ObjectCreate(chart_ID, name, OBJ_HLINE, 0, Time[0], px);
    ObjectSet(name, OBJPROP_COLOR, clr);
    ObjectSet(name, OBJPROP_WIDTH, 2);
    ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(chart_ID, name, OBJPROP_STYLE, style_2);
    ObjectSetInteger(chart_ID, name, OBJPROP_WIDTH, width_2);
    ObjectSetInteger(chart_ID, name, OBJPROP_BACK, back);
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, selection);
    ObjectSetInteger(chart_ID, name, OBJPROP_HIDDEN, hidden);
    WindowRedraw();

    return (true);
}

bool erase_line(string name) {
    ResetLastError();
    ObjectDelete(chart_ID, name);
    if (!ObjectDelete(chart_ID, name)) {
        Print(__FUNCTION__, ": failed to delete the honrizontal line " + name + "; Error code = ", GetLastError());
        return (false);
    }
    return (true);
}

void draw_tunnel_top() {
    draw_line_tunnel(tunnel_top_clr, Tunnel(1), tunnel_top_name);
}

void draw_tunnel_bot() {
    draw_line_tunnel(tunnel_bot_clr, Tunnel(-1), tunnel_bot_name);
}

void draw_tunnel_mid() {
    draw_line(mid_clr, tunnel_mid_px, tunnel_mid_name);
}

void draw_top() {
    draw_line(hi_clr, hi_px, hi_name);
}

void draw_bot() {
    draw_line(lo_clr, lo_px, lo_name);
}

void draw_ptop() {
    draw_line(phi_clr, phi_px, phi_name);
}

void draw_pbot() {
    draw_line(plo_clr, plo_px, plo_name);
}

void erase_tunnel_top() {
    erase_line(tunnel_top_name);
}

void erase_tunnel_bot() {
    erase_line(tunnel_bot_name);
}
void erase_top() {
    erase_line(hi_name);
}

void erase_bot() {
    erase_line(lo_name);
}

void erase_ptop() {
    erase_line(phi_name);
}

void erase_pbot() {
    erase_line(plo_name);
}

void erase_tunnel_mid() {
    erase_line(tunnel_mid_name);
}

//        o-----------------------o
//        |     TUNNEL WIDTH      |      //HiLo +/- Offset
//        o-----------------------o

double Tunnel(int key) {

    double px, offset_points, tunnel_top, tunnel_bot, old_tunnel_top, old_tunnel_bot, tunnel_width, old_tunnel_width, tunnel_max_width_points, tunnel_min_width_points;
    double spread = Ask - Bid;
    double point = 0.00001;
    offset_points = ((tunnel_width_offset * 10 * Bid)) * point;
    tunnel_max_width_points = ((tunnel_max_width * 10 * Ask)) * point;
    tunnel_min_width_points = ((tunnel_min_width * 10 * Bid)) * point;

    tunnel_top = tunnel_top_px + (offset_points / 2);
    tunnel_bot = tunnel_bot_px - (offset_points / 2);
    //   old_tunnel_top = HiLo(2)+(offset_points/2);
    //   old_tunnel_bot = HiLo(4)-(offset_points/2);
    tunnel_width = tunnel_top - tunnel_bot;
    //   old_tunnel_width = old_tunnel_top - old_tunnel_bot;

    if (3 * spread > tunnel_min_width_points) {
        tunnel_min_width_points = 3 * spread;
    }

    if (tunnel_width > tunnel_max_width_points) {
        tunnel_width = tunnel_max_width_points;
        tunnel_top = tunnel_mid_px + (tunnel_max_width_points / 2);
        tunnel_bot = tunnel_mid_px - (tunnel_max_width_points / 2);
    }
    if (tunnel_width < tunnel_min_width_points) {
        tunnel_width = tunnel_min_width_points;
        tunnel_top = tunnel_mid_px + (tunnel_min_width_points / 2);
        tunnel_bot = tunnel_mid_px - (tunnel_min_width_points / 2);
    }

    if (key > 0) {
        px = NormalizeDouble(tunnel_top + TP() * (key - 1), Digits);
    }
    if (key < 0) {
        px = NormalizeDouble(tunnel_bot - TP() * (MathAbs(key) - 1), Digits);
    }
    if (key == 0) {
        px = tunnel_width;
    }
    return (px);
}

//        o-----------------------o
//        |   PLACE 1ST ORDERS    |
//        o-----------------------o

void set_long(double price) {

    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

    if (Ask <= Tunnel(1) - stoplvl) {
        int nb_longs = trade_counter(5);
        int nb_shorts = trade_counter(6);

        int expiration = TimeCurrent() + (PERIOD_M1 * 60) * expiration_mins;
        if (expiration < 600) expiration = 600;

        if (rev_signal == false && nb_longs < max_longs) {

            int ticket = OrderSend(Symbol(), OP_BUYSTOP, lotsize(), price, slippage, 0, price + TP(), "TR " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic, expiration);
            if (ticket < 0) {
                //         Comment("OrderSend Error: ",ErrorDescription(GetLastError()));
            } else {
                //         Comment("Order Sent Successfully, Ticket # is: " + string(ticket));  
            }
        }
        if (rev_signal == true && nb_longs < max_longs) {
            int ticket = OrderSend(Symbol(), OP_BUYLIMIT, lotsize(), price, slippage, 0, price + TP(), "TR " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic, expiration);
            if (ticket < 0) {
                //         Comment("OrderSend Error: " ,ErrorDescription(GetLastError()));
            } else {
                //         Comment("Order Sent Successfully, Ticket # is: " + string(ticket));  
            }
        }
    }
}

void set_short(double price) {

    double stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

    if (Bid >= Tunnel(-1) + stoplvl) {
        int nb_longs = trade_counter(5);
        int nb_shorts = trade_counter(6);

        int expiration = TimeCurrent() + (PERIOD_M1 * 60) * expiration_mins;
        if (expiration < 600) expiration = 600;

        if (rev_signal == false && nb_shorts < max_shorts) {

            int ticket = OrderSend(Symbol(), OP_SELLSTOP, lotsize(), price, slippage, 0, price - TP(), "TR " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic, expiration);
            if (ticket < 0) {
                //         Comment("OrderSend Error: ",ErrorDescription(GetLastError()));
            } else {
                //         Comment("Order Sent Successfully, Ticket # is: " + string(ticket));  
            }
        }
        if (rev_signal == true && nb_shorts < max_shorts) {
            int ticket = OrderSend(Symbol(), OP_SELLLIMIT, lotsize(), price, slippage, 0, price - TP(), "TR " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic, expiration);
            if (ticket < 0) {
                //         Comment("OrderSend Error: " ,ErrorDescription(GetLastError()));
            } else {
                //         Comment("Order Sent Successfully, Ticket # is: " + string(ticket));  
            }
        }
    }
}

//        o-----------------------o
//        |    TRADE FUNCTIONS    |
//        o-----------------------o

void BUY() {
    double TP = TP();

    int ticket = OrderSend(Symbol(), OP_BUY, lotsize(), Ask, slippage, 0, 0, "TR " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic, 0, Turquoise);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
    for (int i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
            OrderModify(OrderTicket(), OrderOpenPrice(), 0, Ask + TP, 0, Turquoise);
        }
    }
}

void SELL() {
    double TP = TP();

    int ticket = OrderSend(Symbol(), OP_SELL, lotsize(), Bid, slippage, 0, 0, "TR " + DoubleToStr(lotsize(), 2) + " on " + Symbol(), magic, 0, Magenta);
    if (ticket < 0) {
        Comment("OrderSend Error: ", ErrorDescription(GetLastError()));
    }
    for (int i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
            OrderModify(OrderTicket(), OrderOpenPrice(), 0, Bid - TP, 0, Magenta);
        }
    }
}

void cancel_long() {
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if ((OrderMagicNumber() == magic) && OrderSymbol() == Symbol()) {
            if (OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT) {
                OrderDelete(OrderTicket());
            }
        }
    }
}

void cancel_short() {
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if ((OrderMagicNumber() == magic) && OrderSymbol() == Symbol()) {
            if (OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP) {
                OrderDelete(OrderTicket());
            }
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
//        |      SPAM ORDERS      |
//        o-----------------------o

//        o-----------------------o
//        |        TP CALC        |
//        o-----------------------o

double TP() {

    int chain_loss, chain_win;

    chain_loss = data_counter(5);
    chain_win = data_counter(6);

    double stoplvl, tplvl, point, tp_offset_points, tunnel_width, xtor;

    stoplvl = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
    point = 0.00001;

    tp_offset_points = ((tp_offset * Bid * 10)) * point;
    xtor = pow(tp_evol_xtor, chain_loss);
    tunnel_width = (Tunnel(0));

    tplvl = NormalizeDouble(((tunnel_width) + tp_offset_points) * xtor, Digits);

    if (tplvl < stoplvl) {
        tplvl = stoplvl;
    }

    return (tplvl);
}

//        o-----------------------o
//        |  LOTS CALC FUNCTION   |
//        o-----------------------o

double lotsize() {

    int chain_loss = data_counter(5);
    int chain_win = data_counter(6);

    double temp_lots, risk_to_SL, mlots = 0;
    double equity = AccountEquity();
    double margin = AccountFreeMargin();
    double maxlot = MarketInfo(Symbol(), MODE_MAXLOT);
    double minlot = MarketInfo(Symbol(), MODE_MINLOT);
    double pip_value = MarketInfo(Symbol(), MODE_TICKVALUE);
    double pip_size = MarketInfo(Symbol(), MODE_TICKSIZE);
    double next_lot;

    int leverage = AccountLeverage();
    double TP = TP();

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
        mlots = NormalizeDouble(temp_lots * (MathPow(xtor, (chain_loss + 1))), 2);
        if (mlots > temp_lots * max_xtor) mlots = NormalizeDouble(temp_lots * max_xtor, 2);

        next_lot = NormalizeDouble(temp_lots * (MathPow(xtor, (chain_loss + 2))), 2);
        if (next_lot > temp_lots * max_xtor) next_lot = NormalizeDouble(temp_lots * max_xtor, 2);
        break;
    case scale:
        mlots = temp_lots + ((increment / 100) * chain_loss) * temp_lots;
        if (mlots > temp_lots * (1 + (max_increment / 100))) mlots = temp_lots * (1 + (max_increment / 100));

        next_lot = temp_lots + ((2 * increment / 100) * chain_loss) * temp_lots;
        if (next_lot > temp_lots * (1 + (2 * max_increment / 100))) next_lot = temp_lots * (1 + (2 * max_increment / 100));
        break;
    case classic:
        mlots = temp_lots;
        break;
    }

    if (mlots < minlot) mlots = minlot;
    if (mlots > maxlot) mlots = maxlot;
    if (next_lot < minlot) next_lot = minlot;
    if (next_lot > maxlot) next_lot = maxlot;

    Comment("Tunnel Top: ", (string) Tunnel(1), " || Tunnel Bot: ", (string) Tunnel(-1), " || Next Recovery Size: ", (string) next_lot, " || Max Size Allowed: ", (string)(temp_lots * max_xtor));

    return (mlots);
}

//        o----------------------o
//        | TRADE FILTR FUNCTION |
//        o----------------------o

bool trading_authorized() {
    int trade_condition = 1;

    if (trade_today() == false) trade_condition = 0;
    if (spread_okay() == false) trade_condition = 0;
    if (filter_off() == false) trade_condition = 0;

    if (trade_condition == 1) {
        return (true);
    } else {
        return (false);
    }
}

bool spread_okay() {
    bool spread_filter_off = true;
    if (trade_counter(7) == 0) {
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

//        o----------------------o
//        |  Earnings FUNCTION   |
//        o----------------------o

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
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0 && count_tot <= max_risk_trades) {
                count_tot++;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0) {
                count_tot = 0;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0 && count_tot > max_risk_trades) {
                count_tot = 0;
            }
        }
        break;

    case (6): //Chain Win
        for (int i = 0; i < OrdersHistoryTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0 && count_tot <= max_risk_trades) {
                count_tot++;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() < 0) {
                count_tot = 0;
            }
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderProfit() > 0 && count_tot > max_risk_trades) {
                count_tot = 0;
            }
        }
        break;

    case (7): //Chart Drawdown % (if equity < balance)
        for (int i = 0; i < OrdersTotal(); i++) {
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
        for (int i = 0; i < OrdersTotal(); i++) {
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
        for (int i = 0; i < OrdersTotal(); i++) {
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
        for (int i = 0; i < OrdersTotal(); i++) {
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
        for (int i = 0; i < OrdersTotal(); i++) {
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
        for (int i = 0; i < OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                count_tot = count_tot + OrderLots() * (OrderOpenPrice());
            }
        }
        break;

    case (20): //(average buying price shorts)
        for (int i = 0; i < OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                count_tot = count_tot + OrderLots() * (OrderOpenPrice());
            }
        }
        break;

    case (21): //Current lots long
        for (int i = 0; i < OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                count_tot = count_tot + OrderLots();
            }
        }

    case (22): //Current lots short
        for (int i = 0; i < OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;

    case (23): //Current lots all
        for (int i = 0; i < OrdersTotal(); i++) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
            if (OrderMagicNumber() == magic && OrderSymbol() == Symbol()) {
                count_tot = count_tot + OrderLots();
            }
        }
        break;
    }
    return (count_tot);
}

//        o-----------------------o
//        |     TRADE COUNTER     |
//        o-----------------------o

int trade_counter(int key) {

    int nb_longs = 0, nb_shorts = 0, nb_buystops = 0, nb_buylimits = 0, nb_sellstops = 0, nb_selllimits = 0, count;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
                if (OrderType() == OP_BUYSTOP) {
                    nb_buystops++;
                }
                if (OrderType() == OP_SELLSTOP) {
                    nb_sellstops++;
                }
                if (OrderType() == OP_BUYLIMIT) {
                    nb_buylimits++;
                }
                if (OrderType() == OP_SELLLIMIT) {
                    nb_selllimits++;
                }
                if (OrderType() == OP_BUY) {
                    nb_longs++;
                }
                if (OrderType() == OP_SELL) {
                    nb_shorts++;
                }
            }
        }
    }
    switch (key) {
    case 1:
        count = nb_buystops;
        break;
    case 2:
        count = nb_sellstops;
        break;
    case 3:
        count = nb_buylimits;
        break;
    case 4:
        count = nb_selllimits;
        break;
    case 5:
        count = nb_longs;
        break;
    case 6:
        count = nb_shorts;
        break;
    case 7:
        count = nb_shorts + nb_longs;
        break;
    }
    return (count);
}

/*       ____________________________________________
         T                                          T
         T                DESIGN GUI                T
         T__________________________________________T
*/

//--- HUD Rectangle
void HUD() {
    ObjectCreate(ChartID(), "HUD", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    //--- set label coordinates
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_XDISTANCE, 0);
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_YDISTANCE, 28);
    //--- set label size
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_XSIZE, 280);
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_YSIZE, 600);
    //--- set background color
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_BGCOLOR, clrBlack);
    //--- set border type
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    //--- set the chart's corner, relative to which point coordinates are defined
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_CORNER, 4);
    //--- set flat border color (in Flat mode)
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_COLOR, clrWhite);
    //--- set flat border line style
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_STYLE, STYLE_SOLID);
    //--- set flat border width
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_WIDTH, 1);
    //--- display in the foreground (false) or background (true)
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_BACK, false);
    //--- enable (true) or disable (false) the mode of moving the label by mouse
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_SELECTED, false);
    //--- hide (true) or display (false) graphical object name in the object list
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_HIDDEN, true);
    //--- set the priority for receiving the event of a mouse click in the chart
    ObjectSetInteger(ChartID(), "HUD", OBJPROP_ZORDER, 0);
}

void GUI() {

    int total_wins = data_counter(1);
    int total_loss = data_counter(2);
    int total_trades = total_wins + total_loss;
    int total_opened_trades = trade_counter(7);

    double total_profit = data_counter(3);
    double total_volumes = data_counter(4);
    int chain_loss = data_counter(5);
    int chain_win = data_counter(6);

    double chart_dd_pc = data_counter(7);
    double acc_dd_pc = data_counter(8);
    double chart_dd = data_counter(9);
    double acc_dd = data_counter(10);

    double chart_runup_pc = data_counter(11);
    double acc_runup_pc = data_counter(12);
    double chart_runup = data_counter(13);
    double acc_runup = data_counter(14);

    double chart_profit = data_counter(15);
    double acc_profit = data_counter(16);

    double gross_profits = data_counter(17);
    double gross_loss = data_counter(18);

    //pnl vs profit factor
    double profit_factor;
    if (gross_loss != 0 && gross_profits != 0) profit_factor = NormalizeDouble(gross_profits / MathAbs(gross_loss), 2);

    //Total volumes vs Average
    double av_volumes;
    if (total_volumes != 0 && total_trades != 0) av_volumes = NormalizeDouble(total_volumes / total_trades, 2);

    //Total trades vs winrate
    int winrate;
    if (total_trades != 0) winrate = (total_wins * 100 / total_trades);

    //Relative DD vs Max DD %
    if (chart_dd_pc < max_dd_pc) max_dd_pc = chart_dd_pc;
    if (acc_dd_pc < max_acc_dd_pc) max_acc_dd_pc = acc_dd_pc;
    //Relative DD vs Max DD $$
    if (chart_dd < max_dd) max_dd = chart_dd;
    if (acc_dd < max_acc_dd) max_acc_dd = acc_dd;

    //Relative runup vs Max runup %
    if (chart_runup_pc > max_runup_pc) max_runup_pc = chart_runup_pc;
    if (acc_runup_pc > max_acc_runup_pc) max_acc_runup_pc = acc_runup_pc;
    //Relative runup vs Max runup $$
    if (chart_runup > max_runup) max_runup = chart_runup;
    if (acc_runup > max_acc_runup) max_acc_runup = acc_runup;

    //Spread vs Maxspread
    if (MarketInfo(Symbol(), MODE_SPREAD) > max_histo_spread) max_histo_spread = MarketInfo(Symbol(), MODE_SPREAD);

    //Chains vs Max chains
    if (chain_loss > max_chain_loss) max_chain_loss = chain_loss;
    if (chain_win > max_chain_win) max_chain_win = chain_win;

    //--- Currency crypt

    string curr = "none";

    if (AccountCurrency() == "USD") curr = "$";
    if (AccountCurrency() == "JPY") curr = "¥";
    if (AccountCurrency() == "EUR") curr = "€";
    if (AccountCurrency() == "GBP") curr = "£";
    if (AccountCurrency() == "CHF") curr = "CHF";
    if (AccountCurrency() == "AUD") curr = "A$";
    if (AccountCurrency() == "CAD") curr = "C$";
    if (AccountCurrency() == "RUB") curr = "руб";

    if (curr == "none") curr = AccountCurrency();

    //--- Equity / balance / floating

    string txt1, content;
    int content_len = StringLen(content);

    txt1 = version + "50";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 75);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "51";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 94);
    }
    ObjectSetText(txt1, "Portfolio", 12, "Century Gothic", color1);

    txt1 = version + "52";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 99);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "100";
    if (AccountEquity() >= AccountBalance()) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 117);
        }

        if (chart_profit == 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 16, "Century Gothic", color3);
        if (chart_profit != 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 11, "Century Gothic", color3);
    }
    if (AccountEquity() < AccountBalance()) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 117);
        }
        if (chart_profit == 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 16, "Century Gothic", color4);
        if (chart_profit != 0) ObjectSetText(txt1, "Equity : " + DoubleToStr(AccountEquity(), 2) + curr, 11, "Century Gothic", color4);
    }

    txt1 = version + "101";
    if (chart_profit > 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 135);
        }
        ObjectSetText(txt1, "Floating chart P&L : +" + DoubleToStr(chart_profit, 2) + curr, 9, "Century Gothic", color3);
    }
    if (chart_profit < 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 135);
        }
        ObjectSetText(txt1, "Floating chart P&L : " + DoubleToStr(chart_profit, 2) + curr, 9, "Century Gothic", color4);
    }
    if (total_opened_trades == 0) ObjectDelete(txt1);

    txt1 = version + "102";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        if (total_opened_trades == 0) ObjectSet(txt1, OBJPROP_YDISTANCE, 152);
        if (total_opened_trades != 0) ObjectSet(txt1, OBJPROP_YDISTANCE, 152);
    }
    if (total_opened_trades == 0) ObjectSetText(txt1, "Balance : " + DoubleToStr(AccountBalance(), 2) + curr, 9, "Century Gothic", color2);
    if (total_opened_trades != 0) ObjectSetText(txt1, "Balance : " + DoubleToStr(AccountBalance(), 2) + curr, 9, "Century Gothic", color2);

    //--- Analytics

    txt1 = version + "53";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 156);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "54";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 175);
    }
    ObjectSetText(txt1, "Analytics", 12, "Century Gothic", color1);

    txt1 = version + "55";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 180);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "200";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 200);
    }
    if (chart_runup >= 0) {
        ObjectSetText(txt1, "Chart runup : " + DoubleToString(chart_runup_pc, 2) + "% [" + DoubleToString(chart_runup, 2) + curr + "]", 8, "Century Gothic", color3);
    }
    if (chart_dd < 0) {
        ObjectSetText(txt1, "Chart drawdown : " + DoubleToString(chart_dd_pc, 2) + "% [" + DoubleToString(chart_dd, 2) + curr + "]", 8, "Century Gothic", color4);
    }

    txt1 = version + "201";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 212);
    }
    if (acc_runup >= 0) {
        ObjectSetText(txt1, "Acc runup : " + DoubleToString(acc_runup_pc, 2) + "% [" + DoubleToString(acc_runup, 2) + curr + "]", 8, "Century Gothic", color3);
    }
    if (acc_dd < 0) {
        ObjectSetText(txt1, "Acc DD : " + DoubleToString(acc_dd_pc, 2) + "% [" + DoubleToString(acc_dd, 2) + curr + "]", 8, "Century Gothic", color4);
    }

    txt1 = version + "202";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 224);
    }
    ObjectSetText(txt1, "Max chart runup : " + DoubleToString(max_runup_pc, 2) + "% [" + DoubleToString(max_runup, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "203";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 236);
    }
    ObjectSetText(txt1, "Max chart drawdon : " + DoubleToString(max_dd_pc, 2) + "% [" + DoubleToString(max_dd, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "204";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 248);
    }
    ObjectSetText(txt1, "Max acc runup : " + DoubleToString(max_acc_runup_pc, 2) + "% [" + DoubleToString(max_acc_runup, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "205";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 260);
    }
    ObjectSetText(txt1, "Max acc drawdown : " + DoubleToString(max_acc_dd_pc, 2) + "% [" + DoubleToString(max_acc_dd, 2) + curr + "]", 8, "Century Gothic", color2);

    txt1 = version + "206";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 271);
    }
    ObjectSetText(txt1, "Trades won : " + IntegerToString(total_wins, 0) + " II Trades lost : " + IntegerToString(total_loss, 0) + " [" + DoubleToString(winrate, 0) + "% winrate]", 8, "Century Gothic", color2);

    txt1 = version + "207";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 284);
    }
    ObjectSetText(txt1, "W-Chain : " + IntegerToString(chain_win, 0) + " [Max : " + IntegerToString(max_chain_win, 0) + "] II L-Chain : " + IntegerToString(chain_loss, 0) + " [Max : " + IntegerToString(max_chain_loss, 0) + "]", 8, "Century Gothic", color2);

    txt1 = version + "208";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 296);
    }
    ObjectSetText(txt1, "Overall volume traded : " + DoubleToString(total_volumes, 2) + " lots", 8, "Century Gothic", color2);

    txt1 = version + "209";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 308);
    }
    ObjectSetText(txt1, "Average volume /trade : " + DoubleToString(av_volumes, 2) + " lots", 8, "Century Gothic", color2);

    txt1 = version + "210";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 320);
    }
    string expectancy;
    if (total_trades != 0) expectancy = DoubleToStr(total_profit / total_trades, 2);

    if (total_trades != 0 && total_profit / total_trades > 0) {
        ObjectSetText(txt1, "Payoff expectancy /trade : " + expectancy + curr, 8, "Century Gothic", color3);
    }
    if (total_trades != 0 && total_profit / total_trades < 0) {
        ObjectSetText(txt1, "Payoff expectancy /trade : " + expectancy + curr, 8, "Century Gothic", color4);
    }
    if (total_trades == 0) {
        ObjectSetText(txt1, "Payoff expectancy /trade : NA", 8, "Century Gothic", color3);
    }

    txt1 = version + "211";
    if (total_trades != 0 && profit_factor >= 1) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 332);
        }
        ObjectSetText(txt1, "Profit factor : " + DoubleToString(profit_factor, 2), 8, "Century Gothic", color3);
    }
    if (total_trades != 0 && profit_factor < 1) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 332);
        }
        ObjectSetText(txt1, "Profit factor : " + DoubleToString(profit_factor, 2), 8, "Century Gothic", color4);
    }
    if (total_trades == 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 332);
        }
        ObjectSetText(txt1, "Profit factor : NA", 8, "Century Gothic", color3);
    }
    //--- Earnings

    txt1 = version + "56";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 335);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "57";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 354);
    }
    ObjectSetText(txt1, "Earnings", 12, "Century Gothic", color1);

    txt1 = version + "58";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 360);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    double profitx = Earnings(0);
    txt1 = version + "300";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 380);
    }
    ObjectSetText(txt1, "Earnings today : " + DoubleToStr(profitx, 2) + curr, 8, "Century Gothic", color2);

    profitx = Earnings(1);
    txt1 = version + "301";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 392);
    }
    ObjectSetText(txt1, "Earnings yesterday : " + DoubleToStr(profitx, 2) + curr, 8, "Century Gothic", color2);

    profitx = Earnings(2);
    txt1 = version + "302";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 404);
    }
    ObjectSetText(txt1, "Earnings before yesterday : " + DoubleToStr(profitx, 2) + curr, 8, "Century Gothic", color2);

    txt1 = version + "303";
    if (total_profit >= 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 416);
        }
        ObjectSetText(txt1, "All time profit : " + DoubleToString(total_profit, 2) + curr, 8, "Century Gothic", color3);
    }
    if (total_profit < 0) {
        if (ObjectFind(txt1) == -1) {
            ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
            ObjectSet(txt1, OBJPROP_CORNER, 4);
            ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
            ObjectSet(txt1, OBJPROP_YDISTANCE, 416);
        }
        ObjectSetText(txt1, "All time loss : " + DoubleToString(total_profit, 2) + curr, 8, "Century Gothic", color4);
    }

    //--- Broker & Account

    txt1 = version + "59";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 419);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "60";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 70);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 438);
    }
    ObjectSetText(txt1, "Broker Information", 12, "Century Gothic", color1);

    txt1 = version + "61";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 443);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "400";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 463);
    }
    ObjectSetText(txt1, "Spread : " + DoubleToString(MarketInfo(Symbol(), MODE_SPREAD), 0) + " pts [Max : " + DoubleToString(max_histo_spread, 0) + " pts]", 8, "Century Gothic", color2);

    txt1 = version + "401";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 475);
    }
    ObjectSetText(txt1, "ID : " + AccountCompany(), 8, "Century Gothic", color2);

    txt1 = version + "402";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 487);
    }
    ObjectSetText(txt1, "Server : " + AccountServer(), 8, "Century Gothic", color2);

    txt1 = version + "403";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 499);
    }
    ObjectSetText(txt1, "Freeze lvl : " + IntegerToString(MarketInfo(Symbol(), MODE_FREEZELEVEL), 0) + " pts II Stop lvl : " + IntegerToString(MarketInfo(Symbol(), MODE_STOPLEVEL), 0) + " pts", 8, "Century Gothic", color2);

    txt1 = version + "404";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 511);
    }
    ObjectSetText(txt1, "L-Swap : " + DoubleToStr(MarketInfo(Symbol(), MODE_SWAPLONG), 2) + curr + "/lot II S-Swap : " + DoubleToStr(MarketInfo(Symbol(), MODE_SWAPSHORT), 2) + curr + "/lot", 8, "Century Gothic", color2);

    txt1 = version + "62";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 514);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "63";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 108);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 533);
    }
    ObjectSetText(txt1, "Account", 12, "Century Gothic", color1);

    txt1 = version + "64";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 0);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 538);
    }
    ObjectSetText(txt1, "_______________________________", 13, "Century Gothic", color1);

    txt1 = version + "500";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 558);
    }
    ObjectSetText(txt1, "ID : " + AccountName() + " [#" + IntegerToString(AccountNumber(), 0) + "]", 8, "Century Gothic", color2);

    txt1 = version + "501";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 570);
    }
    ObjectSetText(txt1, "Leverage : " + (string) AccountLeverage() + ":1", 8, "Century Gothic", color2);

    txt1 = version + "502";
    if (ObjectFind(txt1) == -1) {
        ObjectCreate(txt1, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt1, OBJPROP_CORNER, 4);
        ObjectSet(txt1, OBJPROP_XDISTANCE, 15);
        ObjectSet(txt1, OBJPROP_YDISTANCE, 582);
    }
    ObjectSetText(txt1, "Currency : " + AccountCurrency() + " [" + curr + "]", 8, "Century Gothic", color2);
}

//        o----------------------o
//        |   EA NAME FUNCTION   |
//        o----------------------o

void EA_name() {
    string txt2 = version + "20";
    if (ObjectFind(txt2) == -1) {
        ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt2, OBJPROP_CORNER, 0);
        ObjectSet(txt2, OBJPROP_XDISTANCE, 70);
        ObjectSet(txt2, OBJPROP_YDISTANCE, 27);
    }
    ObjectSetText(txt2, "Relativity", 25, "Century Gothic", color1);

    txt2 = version + "21";
    if (ObjectFind(txt2) == -1) {
        ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt2, OBJPROP_CORNER, 0);
        ObjectSet(txt2, OBJPROP_XDISTANCE, 78);
        ObjectSet(txt2, OBJPROP_YDISTANCE, 68);
    }
    ObjectSetText(txt2, "by Edorenta || version " + version, 8, "Arial", Gray);

    txt2 = version + "22";
    if (ObjectFind(txt2) == -1) {
        ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
        ObjectSet(txt2, OBJPROP_CORNER, 0);
        ObjectSet(txt2, OBJPROP_XDISTANCE, 32);
        ObjectSet(txt2, OBJPROP_YDISTANCE, 51);
    }
    ObjectSetText(txt2, "___________________________", 11, "Arial", Gray);

    /*
       txt2 = version + "23";
       if (ObjectFind(txt2) == -1) {
          ObjectCreate(txt2, OBJ_LABEL, 0, 0, 0);
          ObjectSet(txt2, OBJPROP_CORNER, 0);
          ObjectSet(txt2, OBJPROP_XDISTANCE, 32);
          ObjectSet(txt2, OBJPROP_YDISTANCE, 67);
       }
       ObjectSetText(txt2, "___________________________", 11, "Arial", Gray);

    */
}

/*       ____________________________________________
         T                                          T
         T                 THE END                  T
         T__________________________________________T
*/