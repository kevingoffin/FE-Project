function [C_max, p_pls, p_mns]=maximum_transaction_cost(d_star, u_star, l)
erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
p_pls = erfid(d_star, l)/erfid(u_star,l);
p_mns = erfid(u_star, d_star)/erfid(u_star,l);
C_max = p_pls*(u_star - l) - (d_star - l);

end