function [rtn] = billionaire(X_OS, d_star, u_star, l, c, SIGMA, f, n)
    
    flag_long = false;    % not in a trade
    flag_short = false;    % not in a short trade
    wlt = 1; 
    w_0 = 1;
    v_pls_L = exp(SIGMA*(u_star - d_star - 2*c)) - 1;
    v_mns_L = exp(SIGMA*(l - d_star - 2*c)) - 1;
    v_pls_S = exp(SIGMA*(-u_star + d_star - 2*c)) - 1;
    v_mns_S = exp(SIGMA*(-l + d_star - 2*c)) - 1;
    
    for i=2:length(X_OS)
        % Long

        if X_OS(i) >= d_star && flag_long == false && X_OS(i-1)< d_star && X_OS(i-1)>l
           flag_long = true;
        end
        if X_OS(i) >= u_star && flag_long == true && X_OS(i-1)<u_star
           wlt = wlt*(1+f*v_pls_L); 
           disp('long')
           flag_long = false;
        end
        if X_OS(i) <= l && flag_long == true
           wlt = wlt*(1+f*v_mns_L); 
           flag_long = false;
        end

        % Shorting

        if X_OS(i) <= -d_star && flag_short == false && X_OS(i-1) > -d_star && X_OS(i-1)<-l
           flag_short = true;
        end
        if X_OS(i) <= -u_star && flag_short == true && X_OS(i-1)>-u_star
           wlt = wlt*(1+f*v_mns_S);
           disp('short')
           flag_short = false;
        end
        if X_OS(i) >= -l && flag_short == true
           wlt = wlt*(1+f*v_pls_S); 
           flag_short = false;
        end
    end
   rtn = n*log(wlt/w_0);
end

