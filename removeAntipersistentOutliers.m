function [Rt_clean, time_clean, removed_idx] = removeAntipersistentOutliers(Rt, time, IQR)
    removed_idx = [];
    for t = 2:length(Rt)-1
        if abs(Rt(t) - Rt(t-1)) > IQR && abs(Rt(t+1) - Rt(t)) >= 0.95 * IQR
            removed_idx(end+1) = t;
        end
    end
    Rt_clean = Rt;
    time_clean = time;
    Rt_clean(removed_idx) = [];
    time_clean(removed_idx) = [];
end