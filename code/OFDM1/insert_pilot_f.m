%The pilot function adds a pilot signal
function res = ...
    insert_pilot_f(inp,pilot__seq,pilot__inter,is__pilot_k)
    
if is__pilot_k==1
    [N,Nl] = size(inp);
    Nl_p = Nl+ceil(Nl/pilot__inter);
    res = zeros(N,Nl_p);
    j = 1;
    for i=1:Nl_p
        if mod(i,pilot__inter+1)==1
            res(:,i)=pilot__seq;
        else
            res(:,i)=inp(:,j);
            j = j+1;
        end
    end
else
end

end