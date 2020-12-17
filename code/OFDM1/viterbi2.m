function y=viterbi2(x,G,n,k,m)
%X is the coded signal received
%G is the generation matrix, binary
%（n,k,m）Convolution code
a=size(x);
s=a(2)*k/n;%The decoded sequence is k/n of x
r=zeros(1,s);  %Final result storage
ra=zeros(2^m,s+1);%2^m path
tmmpra=zeros(2^m,s+1);% minimum path each time
Fa=zeros(2^m,1);
%Trans Matrix
g=size(G);
q=g(2)-1;
%b1,b2 Trans Matrix
T1_M=inf(2^m,2^m);
T2_M=inf(2^m,2^m);
for i=0:2^m-1
    z=ten2d(i,q);
    T1_M(i+1,floor((i+8)/2)+1)=mod(1+sum(z.*G(1,2:end)),2);
    T1_M(i+1,floor((i+0)/2)+1)=mod(0+sum(z.*G(1,2:end)),2);
    T2_M(i+1,floor((i+8)/2)+1)=mod(1+sum(z.*G(2,2:end)),2);
    T2_M(i+1,floor((i+0)/2)+1)=mod(0+sum(z.*G(2,2:end)),2);
end
tmmp=0;
%8 status
%s0-s7(binary):000,001,010,011,100,101,110,111
%ra status
%init status is s0
next__state=zeros(2^m,n);%next state
ra_tmmp=zeros(2,s+1);
for j=1:s
    if tmmp >=m
        tmmp = tmmp-1;
        %4th compare
        %Find the four rows with the maximum distance and delete them
        for j=1:4
            [~,d_b]=max(tmmpra(:,j));
            tmmpra(d_b,:)=[];
            ra(d_b,:)=[];
        end
        %add after 4
        for i=1:2^tmmp
            next__state(i,:)=find(T1_M(ra(i,j)+1,:)~=inf)-1;%The next possible state (2 possibilities for each)
            %Calculate the distance between the first possible and the known accepted
            Fa(i,1)=dis(x(2*j-1),x(2*j),T1_M(ra(i,j)+1,next__state(i,1)+1),T2_M(ra(i,j)+1,next__state(i,1)+1));
            %2nd
            Fa(i,2)=dis(x(2*j-1),x(2*j),T1_M(ra(i,j)+1,next__state(i,2)+1),T2_M(ra(i,j)+1,next__state(i,2)+1));
            ra(i+2^tmmp,:)=ra(i,:);
            tmmpra(i+2^tmmp,:)=tmmpra(i,:);
            ra(i,j+1)=next__state(i,1);
            ra(i+2^tmmp,j+1)=next__state(i,2);
            %sum
            tmmpra(i,j+1)=tmmpra(i,j)+Fa(i,1);
            tmmpra(i+2^tmmp,j+1)=tmmpra(i+2^tmmp,j)+Fa(i,2);
        end
        %compare after 4th
        tmmp=tmmp+1;
    else
        for i=1:2^tmmp
            
            %sum 4
            %Current status: RA (I,j), the possible minimum path is TMMPRa (I,j)
            next__state(i,:)=find(T1_M(ra(i,j)+1,:)~=inf)-1;%The next possible state (2 possibilities for each)
            %Calculate the distance between the first possible and the known accepted
            Fa(i,1)=dis(x(2*j-1),x(2*j),T1_M(ra(i,j)+1,next__state(i,1)+1),T2_M(ra(i,j)+1,next__state(i,1)+1));
            %Calculate the distance between the second possibility and the known acceptance
            Fa(i,2)=dis(x(2*j-1),x(2*j),T1_M(ra(i,j)+1,next__state(i,2)+1),T2_M(ra(i,j)+1,next__state(i,2)+1));
            ra(i+2^tmmp,:)=ra(i,:);
            tmmpra(i+2^tmmp,:)=tmmpra(i,:);
            ra(i,j+1)=next__state(i,1);
            ra(i+2^tmmp,j+1)=next__state(i,2);
            %The distance accumulation
            tmmpra(i,j+1)=tmmpra(i,j)+Fa(i,1);
            tmmpra(i+2^tmmp,j+1)=tmmpra(i+2^tmmp,j)+Fa(i,2);
        end
        tmmp=tmmp+1;
    end
end
%Finally, choose the best one of the remaining paths
for j=1:2^tmmp-1
    [~,d_b]=max(tmmpra(:,j+1));
    tmmpra(d_b,:)=[];
    ra(d_b,:)=[];
end
r=ra(2:end);%The state after the first moment, the initial state is 0
for i=1:size(r,2)-m
    y(:,i)=ten2d(r(i),m);
end
y=y(1,:);