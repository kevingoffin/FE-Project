function [opt] = f_opt(u_star, d_star, l, c_bar, SIGMA, p_pls, p_mns)

    v_pls = exp(SIGMA*(u_star - d_star - c_bar)) - 1;
    v_mns = exp(SIGMA*(l - d_star - c_bar)) - 1;
    q_pls = v_mns/(v_mns - v_pls);
    if p_pls > q_pls
        f_star = -(p_pls/v_mns + p_mns/v_pls);
    else
        f_star = 0;
    end
    max_leverage = 100;    % to be changed
    opt = min(f_star, max_leverage);

end