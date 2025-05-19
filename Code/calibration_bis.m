function [eta_hat, k_hat, sigma_hat] = calibration_bis(Rt_IS_NY_Filtered, deltaT, flag)


    if flag == 1       % flag is 1 if the data are a table
        x_min_one = table2array(Rt_IS_NY_Filtered(1:end-1, 2));
        x_i = table2array(Rt_IS_NY_Filtered(2:end, 2));
        len = size(Rt_IS_NY_Filtered,1)-1;
    else
        x_min_one = Rt_IS_NY_Filtered(1:end-1);
        x_i = Rt_IS_NY_Filtered(2:end);
        len = size(Rt_IS_NY_Filtered,1)-1;
    end

    Y_min = mean(x_min_one);
    Y_pls = mean(x_i);

    Y_min_min = mean(x_min_one.^2);
    Y_pls_pls = mean(x_i.^2);
    
    Y_pls_min = (1/len) * sum(x_min_one.*x_i);
    
    % parameters
    num = Y_pls_min - Y_min * Y_pls;
    den = Y_min_min - Y_min^2;
    
    eta_hat = Y_pls + ((x_i(end) - x_min_one(1))/(len))*(num)/((den) - (num));
    zeta_hat = Y_pls_pls - Y_pls^2 - num^2/den;
    k_hat = -(1/deltaT)*log(num/den);      
    sigma_hat = sqrt((zeta_hat*2*k_hat)/(1-exp(-2*k_hat*deltaT)));
end