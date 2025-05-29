function [C, expected_C, SIGMA, c_bar, theta]=computeC(bid_HO, bid_LGO, ask_HO, ask_LGO, flag, timestamp, time_IS_NY,time_OS_NY, sigma_hat, k_hat)
[bid_HO_IS_filtered, bid_HO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(bid_HO, timestamp, 9);
[ask_HO_IS_filtered, ask_HO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(ask_HO, timestamp, 9);
[bid_LGO_IS_filtered, bid_LGO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(bid_LGO, timestamp, 9);
[ask_LGO_IS_filtered, ask_LGO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(ask_LGO, timestamp, 9);
[bid_HO_IS_NY_Filtered, bid_HO_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, bid_HO_IS_filtered, bid_HO_OS_filtered, 8, 16, flag);
[ask_HO_IS_NY_Filtered, ask_HO_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, ask_HO_IS_filtered, ask_HO_OS_filtered, 8, 16, flag);
[bid_LGO_IS_NY_filtered, bid_LGO_OS_NY_filtered] = filter_NY(time_IS_NY, time_OS_NY, bid_LGO_IS_filtered, bid_LGO_OS_filtered, 8, 16, flag);
[ask_LGO_IS_NY_filtered, ask_LGO_OS_NY_filtered] = filter_NY(time_IS_NY, time_OS_NY, ask_LGO_IS_filtered, ask_LGO_OS_filtered, 8, 16, flag);

C = log(table2array(ask_HO_IS_NY_Filtered(:,2))./table2array(bid_HO_IS_NY_Filtered(:,2))) + log(table2array(ask_LGO_IS_NY_filtered(:,2))./table2array(bid_LGO_IS_NY_filtered(:,2)));
expected_C = mean(C);
SIGMA=sigma_hat/sqrt(2*k_hat);
c_bar = expected_C/SIGMA;
theta = 1/k_hat;
end