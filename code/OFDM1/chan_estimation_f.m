function res = chan_estimation_f(inp,H,pilot__seq,pilot__interval)
%Channel Estimation
[N,Nl] = size(inp);
Ml = size(H,2);
Hout = zeros(N,Ml);
res = zeros(N,Nl);
for i=1:Ml
    Hout(:,i)=H(:,i)./pilot__seq;
end
for j=1:Ml

    hs = inv(diag(Hout(:,j),0));
    if j==Ml
        Y = inp(:,((j-1)*pilot__interval+1):end);
        res(:,((j-1)*pilot__interval+1):end)=hs*Y;
    else
        Y = inp(:,((j-1)*pilot__interval+1):j*pilot__interval);
        res(:,((j-1)*pilot__interval+1):j*pilot__interval)=hs*Y;
    end
end
    
end