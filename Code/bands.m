function [u_star, d_star, mu_star] = bands(c_bar, l, SIGMA, theta, f)
    
    c_vals = linspace(0.001, 0.75, 100);
    [d_vals, u_vals] = maximize_mu(c_vals, l, SIGMA, theta, f);
    [~, idx] = min(abs(c_vals - c_bar));
    d_star = d_vals(idx);
    u_star = u_vals(idx);
    mu_star = evaluate_mu(d_star, u_star, c_bar, theta, l, SIGMA, f);

end