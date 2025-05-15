function [ann_pct_return] = billionaire(X_OS, d_star, u_star, l, c, Rt_OS_NY_Filtered, SIGMA)

    
    flag = false;    % not in a trade
    rtn = 0;
    count = 0;
    
    for i=1:length(X_OS)
        if X_OS(i) >= d_star && flag == false && X_OS(i-1)<d_star && X_OS(i-1)>l
           flag = true;
           count = count + 1;
        end
        if X_OS(i) >= u_star && flag == true
           rtn = rtn + (u_star - d_star - 2*c);
           flag = false;
        end
        if X_OS(i) <= l && flag == true
           rtn = rtn + (-d_star + l - 2*c);
           flag = false;
        end
    end
    
    yearsOS = years(table2array(Rt_OS_NY_Filtered(end,1)) - table2array(Rt_OS_NY_Filtered(1,1)));
    ann_log_return = rtn * SIGMA / yearsOS;    % log-return per anno
    ann_pct_return = (exp(ann_log_return) - 1) * 100;
end