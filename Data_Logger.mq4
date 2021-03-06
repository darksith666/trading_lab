/*      .=====================================.
       /              Data Logger              \
      |               by Edorenta               |
       \          Signature Algorithms         /
        '====================================='
*/

#property link          "https://github.com/Edorenta"
#property copyright     "Signature Algorithms™"
#property description   "This Logger purpose is to keep track of the broker activity \n Targeted Data: \n - Spread (Min/Max/Median) \n - Open/High/Low/Close \n - Ticks per Minute"
#property version       "2"
string    version =     "2";
#property strict
#include <stdlib.mqh>

// Global variables (nonr e-declaration on every tick)

double spread, min_spread, med_spread, mean_spread, max_spread;
double last, high, low, open, close, med_price, mean_price;
int volume;
double spread_array[], price_array[];

string file_header, file_body, file_footer;
string format_date, format_hour;
string filename, terminal_data_path, file_path;
string comment;
extern string folder_name = "default"; //Sub Fodler [Default=/Data Logs/Sym]

int i, j, ticks;
int minute, day;
int file_handle, write_file;

/*
      .-----------------------.
      |    ON INIT FUNCTION   |
      '-----------------------'
       
      >> On init will check if our file exists and if not, create it.
      >> The file will be entitled "XXXXXX" & "_" & "JJMMYYYY" & "_log"
*/

int init() {
    if (!MarketInfo(_Symbol, MODE_ASK)) {
        Alert("Please add ", _Symbol, " to your Market Watch.");
    };
    if (folder_name == "default") {
        folder_name = "data logs\\" + _Symbol;
    }

    //      EventSetTimer(5);

    filename = _Symbol + "_" + Now(1) + "" + Now(2) + "" + Now(3) + "_log.txt"; //.txt
    terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);
    //      file_path          = terminal_data_path+"\\" + folder_name + "\\"+ filename;
    file_path = folder_name + "\\" + filename;
    file_handle = FileOpen(file_path, FILE_READ | FILE_SHARE_READ | FILE_WRITE | FILE_ANSI);
    file_header = filename + "\n" + "Date;Hour;Open;High;Low;Close;MedPrice;MeanPrice;MinSpread;MedSpread;MeanSpread;MaxSpread;Volumes;Ticks;" + "\n";

    if (file_handle < 0) {
        Print("Failed to open the file by the absolute path " + file_path);
        Print("Error code ", GetLastError());
    } else {
        if (FileSeek(file_handle, 0, SEEK_END)) {
            Print("appending to file");
        }
        write_file = FileWrite(file_handle, file_header);
        if (write_file < 0) {
            Print("Failed to write the file in " + file_path);
        }
    }

    minute = StringToInteger(Now(5)) - 1;
    day = StringToInteger(Now(3));
    FileClose(file_handle);
    comment = file_handle + "\n" + "File Name: " + filename + "\n" + file_body + "\n" + "File Directory: " + terminal_data_path + "\\MQL4\\Files\\" + file_path;
    Comment(comment);
    return (INIT_SUCCEEDED);
}

/*
      .-------------------------.
      |    ON DEINIT FUNCTION   |
      '-------------------------'
      
      >> Write "Shut down at " & "JJMMYYYY-HH:MM:SS" on the last line of the text file
      >> Notify the user on the chart that the data isn't logging anymore
*/

int deinit() {
    file_handle = FileOpen(file_path, FILE_WRITE | FILE_TXT | FILE_ANSI);

    if (file_handle < 0) {
        Print("Failed to open the file by the absolute path " + file_path);
        Print("Error code ", GetLastError());
    }
    format_date = Now(1) + "/" + Now(2) + "/" + Now(3);
    format_hour = Now(4) + ":" + Now(5);

    file_footer = format_date + ";" + format_hour + ";DATA LOGGER STOPPED ON " + _Symbol;
    if (FileSeek(file_handle, 0, SEEK_END)) {
        Print("appending to file");
    }
    write_file = FileWrite(file_handle, file_footer);
    if (write_file < 0) {
        Print("Failed to write the file in " + file_path);
        Print("Error code ", GetLastError());
    }
    FileClose(file_handle);
    Comment(file_footer);
    return (0);
}

/*
      .-----------------------.
      |    ON TICK FUNCTION   |
      '-----------------------'
      
      >> On every Tick, check what second we're on to either keep on logging or clear the cache and move on to the next minute
      >> Set a min/max/median counter for spread
      >> If the minute is ending HH:MM:59 => log and write:
         "YYYY/MM/DD;HH:MM;Open;High[0];Low[0];Close[0];min_spread;median_spread;max_spread;ticks"
      >> Notify the user on the chart that the data isn't logging anymore

void OnTimer()
{
   comment = comment + "\n"+"New Log in: "+ IntegerToString(60-Seconds());
   Comment(comment);
}
*/

void OnTick() {
    last = NormalizeDouble((Ask + Bid) / 2, Digits);
    spread = Ask - Bid;

    //   j           = NormalizeDouble(ticks/2,0);          //Median Tick

    if (StrToInteger(Now(3)) != day) {
        init();
    }

    if (Minute() != minute) {
        if (ArraySize(price_array) >= 2) {
            med_price = ArrayMedian(price_array);
            med_spread = ArrayMedian(spread_array);
            mean_price = iMAOnArray(price_array, 0, ticks, 0, MODE_SMA, 0);
            mean_spread = iMAOnArray(spread_array, 0, ticks, 0, MODE_SMA, 0);
        } else {
            med_spread = spread;
            med_price = last;
            mean_spread = spread;
            mean_price = last;
        }

        format_date = Now(1) + "/" + Now(2) + "/" + Now(3);
        format_hour = Now(4) + ":" + Now(5);
        volume = Volume[1];
        file_body = format_date + ";" + format_hour + ";" + DoubleToStr(open) + ";" + DoubleToStr(high) + ";" + DoubleToStr(low) + ";" + DoubleToStr(close) + ";" + DoubleToStr(med_price) + ";" + DoubleToStr(mean_price) + ";" + DoubleToStr(min_spread) + ";" + DoubleToStr(med_spread) + ";" + DoubleToStr(mean_spread) + ";" + DoubleToStr(max_spread) + ";" + IntegerToString(volume) + ";" + IntegerToString(ticks) + ";";

        file_handle = FileOpen(file_path, FILE_READ | FILE_SHARE_READ | FILE_WRITE | FILE_ANSI);

        if (FileSeek(file_handle, 0, SEEK_END)) {
            Print("appending to file");
        }
        if (file_handle < 0) {
            Print("Failed to open the file by the absolute path " + file_path);
            Print("Error code ", GetLastError());
        }
        write_file = FileWrite(file_handle, file_body);
        if (write_file < 0) {
            Print("Failed to write the file in " + file_path);
            Print("Failed to write the file in " + file_path);
            Print("Error code ", GetLastError());
        }
        FileClose(file_handle);
        max_spread = spread;
        min_spread = spread;
        high = last;
        low = last;

        ticks = 0;
        minute = Minute();
        day = StrToInteger(Now(3));
        open = last;
        comment = file_handle + "\n" + "File Name: " + filename + "\n" + file_body + "\n" + "File Directory: " + terminal_data_path + "\\MQL4\\Files\\" + file_path + "\n" + "Elapsed Ticks in the minute: " + IntegerToString(1 + ticks);
        Comment(comment);
    } else {
        ticks++;
        max_spread = MathMax(spread, max_spread);
        min_spread = MathMin(spread, min_spread);
        low = MathMin(last, low);
        high = MathMax(last, high);

        ArrayResize(spread_array, ticks + 1, 0);
        ArrayResize(price_array, ticks + 1, 0);
        spread_array[ticks] = spread;
        price_array[ticks] = last;
        close = last;
    }
}

double ArrayMedian(double & array[]) {

    double median;
    double copy[];
    int len = ArraySize(array);

    ArrayResize(copy, len);
    ArrayCopy(copy, array, 0, 0, WHOLE_ARRAY);
    ArraySort(copy, WHOLE_ARRAY, 0, MODE_DESCEND);
    if (len % 2 == 0) // it's even
    {
        median = (copy[len / 2] + copy[(len / 2) - 1]) / 2.0;
    } else // it's odd
    {
        median = copy[len / 2];
    }
    return (median);
}

string Now(int key) {

    string str_year, str_month, str_day, str_hour, str_minute, str_second;
    datetime now = TimeGMT();
    MqlDateTime str_date;
    TimeToStruct(now, str_date);

    str_year = IntegerToString(str_date.year);
    str_month = IntegerToString(str_date.mon);
    str_day = IntegerToString(str_date.day);
    str_hour = IntegerToString(str_date.hour);
    str_minute = IntegerToString(str_date.min);
    str_second = IntegerToString(str_date.sec);

    if (StringLen(str_month) < 2) {
        while (StringLen(str_month) < 2) {
            str_month = "0" + str_month;
        }
    }
    if (StringLen(str_day) < 2) {
        while (StringLen(str_day) < 2) {
            str_day = "0" + str_day;
        }
    }
    if (StringLen(str_hour) < 2) {
        while (StringLen(str_hour) < 2) {
            str_hour = "0" + str_hour;
        }
    }
    if (StringLen(str_minute) < 2) {
        while (StringLen(str_minute) < 2) {
            str_minute = "0" + str_minute;
        }
    }
    if (StringLen(str_second) < 2) {
        while (StringLen(str_second) < 2) {
            str_second = "0" + str_second;
        }
    }
    switch (key) {
    case 1:
        return str_year;
        break;
    case 2:
        return str_month;
        break;
    case 3:
        return str_day;
        break;
    case 4:
        return str_hour;
        break;
    case 5:
        return str_minute;
        break;
    case 6:
        return str_second;
        break;
    }
    return ("Error");
}

//+------------------------------------------------------------------+