function [ann_pct_return] = billionaire(X_OS, d_star, u_star, l, c, Rt_OS_NY_Filtered, SIGMA)
% BILLIONAIRE Calculates annualized percentage return for a trading strategy
%
% Inputs:
%   X_OS                - Time series of trading signal values
%   d_star              - Entry threshold (lower bound)
%   u_star              - Profit-taking threshold (upper bound)
%   l                   - Stop-loss threshold
%   c                   - Transaction cost per trade (fixed)
%   Rt_OS_NY_Filtered   - Table with timestamps for return annualization
%   SIGMA               - Volatility scaling factor
%
% Output:
%   ann_pct_return      - Annualized percentage return of strategy

    % Initialize trade tracking variables
    flag = false;    % false = no active trade, true = in trade
    rtn = 0;         % Cumulative raw return
    count = 0;       % Trade counter
    
    % Loop through trading signal values
    for i = 2:length(X_OS)  % Start at 2 to compare with previous value     
        % ENTRY CONDITION: Signal crosses d_star upward from below
        if X_OS(i) >= d_star && flag == false && X_OS(i-1) < d_star && X_OS(i-1) > l
           flag = true;    % Open trade
           count = count + 1;
        end
        
        % EXIT CONDITION 1: Take profit at u_star
        if X_OS(i) >= u_star && flag == true
           rtn = rtn + (u_star - d_star - 2*c);  % Profit minus transaction costs
           flag = false;   % Close trade
        elseif X_OS(i) <= l && flag == true % EXIT CONDITION 2: Stop loss at l
           rtn = rtn + (-d_star + l - 2*c);      % Loss minus transaction costs
           flag = false;   % Close trade
        end
    end
    
    % Calculate time period in years for annualization
    start_date = table2array(Rt_OS_NY_Filtered(1,1));
    end_date = table2array(Rt_OS_NY_Filtered(end,1));
    yearsOS = years(end_date - start_date);
    
    % Convert raw return to annualized percentage
    ann_log_return = rtn * SIGMA / yearsOS;       % Annualized log-return
    ann_pct_return = (exp(ann_log_return) - 1) * 100;  % Convert to percentage
    
    % Optional: Display trade count for debugging
    fprintf('Total trades executed: %d\n', count);
end