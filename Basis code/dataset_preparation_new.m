function [timestamp_new, mid_IKA, mid_OATA, mid_OEA, mid_RXA, Rt_pair_1, Rt_pair_2]=dataset_preparation_new(T_new)
timestamp_new = T_new{:, 1};
mid_IKA    = T_new{:, 2};   
mid_OATA   = T_new{:, 3};  
mid_OEA    = T_new{:, 4};  
mid_RXA   = T_new{:, 5};   

valid_idx_new = ~isnan(mid_IKA) & ~isnan(mid_OATA) &  ~isnan(mid_OEA) & ~isnan(mid_RXA);
timestamp_new = timestamp_new(valid_idx_new);
mid_IKA = mid_IKA(valid_idx_new);
mid_OATA = mid_OATA(valid_idx_new);
mid_OEA = mid_OEA(valid_idx_new);
mid_RXA = mid_RXA(valid_idx_new);

Rt_pair_1 = log(mid_IKA./mid_RXA);       % pair IKA, RXA
Rt_pair_2 = log(mid_OATA./mid_OEA);        % pair OATA, OEA

end