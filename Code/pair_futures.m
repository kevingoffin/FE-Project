function [d_vals, u_vals, d_star, u_star, c_bar, SIGMA, theta, expected_C] = pair_futures(mid_fut1, mid_fut2, sigma_hat1, k_hat1, l, f, c_vals)
    bid_fut1_IS = mid_fut1 - 0.005;
    ask_fut1_IS = mid_fut1 + 0.005;
    bid_fut2_IS = mid_fut2 - 0.005;
    ask_fut2_IS = mid_fut2 + 0.005;

    C = log(ask_fut1_IS./bid_fut1_IS) + log(ask_fut2_IS./bid_fut2_IS);
    expected_C = mean(C);

    SIGMA=sigma_hat1/sqrt(2*k_hat1);
    theta = 1/k_hat1;

    [d_vals, u_vals] = maximize_mu(c_vals, l, SIGMA, theta, f);
    c_bar = expected_C/SIGMA;
    [~, idx] = min(abs(c_vals - c_bar));
    d_star = d_vals(idx);
    u_star = u_vals(idx);

end