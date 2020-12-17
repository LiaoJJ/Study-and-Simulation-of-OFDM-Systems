function [output,H] = get_pilot_f(inp,pilot__interval)
% Separate the data from the block pilot
[N,Nl] = size(inp);
H = zeros(N,ceil(Nl/(1+pilot__interval)));
output = zeros(N,Nl-ceil(Nl/(1+pilot__interval)));
j=1;
k=1;
for i = 1:Nl
    if mod(i,pilot__interval+1)==1
        H(:,j) = inp(:,i);
        j=j+1;
    else
        output(:,k) = inp(:,i);
        k=k+1;
    end
end

end