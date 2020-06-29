c     Scilab ( http://www.scilab.org/ ) - This file is part of Scilab
c     Copyright (C) INRIA
c 
c     Copyright (C) 2012 - 2016 - Scilab Enterprises
c
c This file is hereby licensed under the terms of the GNU GPL v2.0,
c pursuant to article 5.3.4 of the CeCILL v.2.1.
c This file was originally licensed under the terms of the CeCILL v2.1,
c and continues to be available under such terms.
c For more information, see the COPYING file which you should have received
c along with this program.
c
      subroutine zqnbd(indqn,simul,dh,n,binf,bsup,x,f,g,zero,napmax,
     &     itmax,indic,izig,nfac,epsx,epsf,epsg,x1,x2,g1,dir,df0,
     &ig,in,irel,izag,iact,epsrel,ieps1,izs,rzs,dzs)
c
      implicit double precision (a-h,o-z)
      real rzs(*)
      double precision dzs(*)
      dimension x1(n),x2(n),g1(n),dir(n),epsx(n)
      dimension binf(n),bsup(n),x(n),g(n),dh(*),indic(n),izig(n),
     &izs(*)
      external simul,proj
c
c$$$      if(iprint.lt.4)go to 3
c$$$      write(bufstr,1020)izag,ig,in,irel,iact,epsrel
c$$$      call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$1020  format(' qnbd :  izag,ig,in,irel,iact,epsrel=',5i3,f11.4)
c$$$c
c$$$      if(ig.eq.1) then
c$$$        write(bufstr,110)
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$110   format(' test sur gradient pour sortie ib')
c$$$      if(in.eq.1) then 
c$$$        write(bufstr,111)
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$111   format(' test sur nombre de defactorisations pour sortie ib')
c$$$      if(izag.ne.0) then
c$$$        write(bufstr,112)izag
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$112   format(' memorisation de variables izag=',i3)
c$$$      if(irel.eq.1) then
c$$$        write(bufstr,114)epsrel
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$114   format(' methode de minimisations incompletes ; epsrel=',d11.4)
c$$$      if(iact.eq.1) then
c$$$        write(bufstr,116)
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$116   format(' blocage des variables dans ib')
c$$$      if(ieps1.eq.1) then
c$$$        write(bufstr,118)
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$118   format(' parametre eps1 nul')
c$$$      if(ieps1.eq.2) then
c$$$        write(bufstr,119)
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$119   format(' parametre eps1 grand')
c$$$c
c$$$c     cscal1 utilise pour calculer eps(x) = eps1 cf avant 310
c$$$      cscal1=1.0d+8
c$$$      if(ieps1.eq.2) then
c$$$        write(bufstr,120)cscal1
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$120   format(' parametre eps1=eps(x) calcule avec cscal1=',d11.4)
c$$$3     continue
c
      difg0=1.0d+0
      difg1=0.0d+0
c
c     eps0 sert a partitionner les variables
      eps0=0.0d+0
      do i=1,n
         izig(i)=0
         eps0=eps0+epsx(i)
      end do
      eps0=10.*eps0/n
c
c     section 1  mise en forme de dh
c     si indqn=1 on init dh a ident puis scal a it=2
c
      call proj(n,binf,bsup,x)
      ndh=n*(n+1)/2
      if(indqn.eq.1)go to 10
      if(indqn.eq.2)go to 30
c     erreur
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,105)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$105   format(' qnbd  : valeur non admissible de indqn  ',i5)
      indqn=-105
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
      return
10    continue
c     on initialise dh a l identite puis a l iteration 2
c     on met a l echelle
      nfac=0
      do i=1,n
         indic(i)=i
      end do
      do i=1,ndh
         dh(i)=0.0d+0
      end do 
30    continue
c
c     section 2  mise a jour dh
c
c     iter nombre d iterations de descente
      iter=0
      scal=1.0d+0
      nap=1
      indsim=4
      if(indqn.eq.1) call simul(indsim,n,x,f,g,izs,rzs,dzs)
      if(indsim.le.0)then
      indqn=-1
      if(indsim.eq.0)indqn=0
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$123   format(' qnbd : indqn=',i8)
      return
      endif
      if(indqn.ne.1)go to 200
c     mise a echelle dh
c     df0 decroissance prevue . si mod quad df0=((dh)-1g,g)/2
c     et on cherche dh diag de la forme cst/(dx)**2
c     d ou cst=som((y(i)*(dx))**2))/(2*df0)
      cof1=0.0d+0
      do i=1,n
         cof1=cof1+(g(i)*epsx(i))**2
      end do
      cof1=cof1/(2.0d+0*df0)
      i1=-n
      do i=1,n
         i1=i1+n+2-i
         dh(i1)=(cof1 + zero)/(epsx(i)**2 + zero)
      end do
      iconv=0
200   iter=iter +1
      if(iter.le.itmax)go to 202
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,1202)
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$1202  format(' qnbd : maximum d iterations atteint')
      indqn=5
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
      return
c$$$202   if(iprint.ge.2) then
c$$$         write(bufstr,1210)iter,f
c$$$         call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$         endif
c$$$1210  format(' qnbd : iter=',i3,'  f=',d15.7)
c     x1,g1 valeurs a l iteration precedente
202   if(iter.eq.1)go to 300
      cof1=0.0d+0
      do i=1,n
         x1(i)=x(i)-x1(i)
         g1(i)=g(i)-g1(i)
         cof1=cof1 + x1(i)*g1(i)
      end do
      if(cof1.le.zero)go to 250
      if(iter.gt.2.or.indqn.ne.1)go to 250
c     mise a l echelle de dh par methode shanno-phua
c      dh=(y,y)/(y,s)*id
      cof2=0.0d+0
      do i=1,n
         cof2=cof2 + g1(i)**2
      end do
      cof2=cof2/cof1
c$$$      if(iprint.gt.3) then
c$$$        write(bufstr,1203)cof2
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$1203  format(' qnbd : facteur d echelle=',d11.4)
      dh(1)=cof2
      i1=1
      do i=1,nfac
         i1=i1+n+1-i
         dh(i1)=cof2
      end do
c
c     scal= (y,s)/(y,y)
c     scal sert de coeff a g dans le calcul de dir pour i dans ib
      scal=1.0d+0/cof2
250   continue
c
c     mise a jour dh par methode bfgs (majour) si iter ge 2
c     dh1=dh +y*yt/(y,s) - dh*s*st*dh/(s,dh*s)
c     exprimons ds=x1 et y=g1 dans les nouv variables soit x2 et g1
      do i=1,n
         i1=indic(i)
         x2(i1)=g1(i)
         dir(i1)=x1(i)
      end do
      do i=1,n
         g1(i)=x2(i)
      end do
      do i=1,n
         i1=indic(i)
         x2(i1)=x1(i)
      end do
c     on stocke d abord dh*s dans x2
c     calcul des nfac premieres variables,en deux fois
      continue
      if(nfac.eq.0) go to 2312
      if(nfac.gt.1) go to 2300
      dir(1)=dir(1)*dh(1)
      go to 2312
2300  continue
      np=nfac+1
      ii=1
      n1=nfac-1
      do i=1,n1
         y=dir(i)
         if(dh(ii).eq.0.0d+0) go to 2302
         ij=ii
         ip=i+1
         do j=ip,nfac
            ij=ij+1
            y=y+dir(j)*dh(ij)
         end do
 2302    dir(i)=y*dh(ii)
         ii=ii+np-i
      end do
      dir(nfac)=dir(nfac)*dh(ii)
      do k=1,n1
         i=nfac-k
         ii=ii-np+i
         if(dir(i).eq.0.0d+0) go to 2311
         ip=i+1
         ij=ii
         y=dir(i)
         do j=ip,nfac
            ij=ij+1
            dir(j)=dir(j)+dh(ij)*dir(i)
         end do
      end do
2311  continue
2312  continue
      nfac1=nfac+1
      n2fac=(nfac*nfac1)/2
      nnfac=n-nfac
      k=n2fac
      if(nfac.eq.n)go to 268
      do i=nfac1,n
         dir(i)=0.0d+0
      end do
      if(nfac.eq.0)go to 265
      do i=1,nfac
         do j=nfac1,n
            k=k+1
            if(x2(j).eq.0.)go to 260
            dir(i)= dir(i) + dh(k)*x2(j)
         end do
      end do
260   continue
c     calcul autres comp de dh*s=d en deux fois
      k=n2fac
      do j=1,nfac
         do i=nfac1,n
            k=k+1
            dir(i)=dir(i) + dh(k)*x2(j)
         end do
      end do
265   continue
      k=n2fac+nfac*nnfac
      do j=nfac1,n
         do i=j,n
            k=k+1
            if(x2(j).eq.0.)go to 266
            dir(i)=dir(i) + dh(k)*x2(j)
         end do
      end do
266   continue
      if(nfac.eq.n-1)go to 268
      nm1=n-1
      k=n2fac+nfac*nnfac
      do 267 i=nfac1,nm1
      k=k+1
      i1=i+1
      do j=i1,n
         k=k+1
         if(x2(j).eq.0.)go to 267
         dir(i)=dir(i)+dh(k)*x2(j)
      end do
267   continue
c     calcul de dh*s fini
c     calcul sig1 pour 2eme mise a jour
268   sig1=0.0d+0
      do i=1,n
         sig1=sig1+dir(i)*x2(i)
      end do
      if(sig1.gt.0.0d+0)go to 272
c
c     ******************************************************
      indqn=8
      if(iter.eq.1)indqn=-5
272      sig1=-1.0d+0/sig1
c     truc powell si (y,s) negatif
      if(cof1.gt.zero)go to 277
      teta=-1.0d+0/sig1
      teta=.8*teta/(teta-cof1)
      teta1=1.0d+0-teta
      do i=1,n
         g1(i)=teta*g1(i)+teta1*dir(i)
      end do
      cof1=-.2/sig1
277   continue
c
c      premiere mise a jour de dh
      sig=1.0d+0/cof1
      zsig1=1.0d+0/sig1
      mk=0
      ir=nfac
      epsmc=1.0d-9
      call calmaj(dh,n,g1,sig,x2,ir,mk,epsmc,nfac)
      if(ir.ne.nfac)go to 280
      call calmaj(dh,n,dir,sig1,x2,ir,mk,epsmc,nfac)
      if(ir.ne.nfac)go to 280
      go to 300
c$$$280   if(iprint.gt.0) then
c$$$         write(bufstr,282)
c$$$         call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$         endif
c$$$282   format(' qnbd : pb dans appel majour')
280   indqn=8
      if(iter.eq.1)indqn=-5
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$  endif
      return
 300  continue
c     
c     section 3 determination des variables libres et bloquees
c     
c     calcul eps1
c     
      scal1=scal
      if(ieps1.eq.1)scal1=0.0d+0
      if(ieps1.eq.2)scal1=scal*cscal1
      do i=1,n
         x1(i)=x(i)-scal1*abs(g(i))*g(i)
      end do
      call proj(n,binf,bsup,x1)
      eps1=0.0d+0
      do i=1,n
         eps1=eps1 + abs(x1(i)-x(i))
      end do
      eps1=min(eps0,eps1)
      if(ieps1.eq.1)eps1=0.0d+0
      if(ieps1.eq.2)eps1=eps1*1.0d+4
      ifac=0
      idfac=0
      k=0
c     
c     
      gr=0.0d+0
      if(ig.eq.1)gr=0.2*difg/n
      n3=n
      if(in.eq.1)n3=n/10
c     si irit=1 on peut relacher des variables
      irit=0
      if(difg1.le.epsrel*difg0)irit=1
      if(irel.eq.0.or.iter.eq.1)irit=1
c     
      tiers=1.0d+0/3.0d+0
      do k=1,n
         izig(k)=izig(k)-1
         if(izig(k).le.0)izig(k)=0
         bi=binf(k)
         bs=bsup(k)
         ic=indic(k)
         d1=x(k)-bi
         d2=bs-x(k)
         dd=(bs-bi)*tiers
         ep=min(eps1,dd)
         if(d1.gt.ep)go to 324
         if(g(k).gt.0.)go to 330
         go to 335
 324     if(d2.gt.ep)go to 335
         if(g(k).gt.0.)go to 335
         go to 330
c     on defactorise si necessaire
 330     continue
         if(ic.gt.nfac)go to 340
         idfac=idfac+1
         mode=-1
         izig(k)=izig(k) + izag
         call ajour(mode,n,k,nfac,dh,x2,indic)
         if(mode.eq.0) go to 340
         indqn=8
         if(iter.eq.1)indqn=-5
         return
c     on factorise
 335     continue
         if(irit.eq.0)go to 340
         if(ic.le.nfac)go to 340
         if(izig(k).ge.1)go to 340
         mode=1
         if(ifac.ge.n3.and.iter.gt.1)go to 340
         if(abs(g(k)).le.gr)go to 340
         ifac=ifac+1
         call ajour(mode,n,k,nfac,dh,x2,indic)
         if(mode.eq.0)go to 340
         indqn=8
         if(iter.eq.1)indqn=-5
         return
      end do
 340  continue
c
c     *********************************************** a voir
      if(iconv.eq.1)return
c
c     section 6 resolution systeme lineaire et expression de dir
c     on inverse le syst correspondant aux nl premieres composantes
c     dans le nouveau syst d indices
      ir=nfac
      do i=1,n
         i1=indic(i)
         x2(i1)=g(i)
      end do
      if(ir.lt.nfac) go to 412
      if(nfac.gt.1) go to 400
      x2(1)=x2(1)/dh(1)
      go to 412
400   continue
      do i=2,nfac
         ij=i
         i1=i-1
         v=x2(i)
         do j=1,i1
            v=v-dh(ij)*x2(j)
            ij=ij+nfac-j
         end do
         x2(i)=v
         x2(i)=v
      end do
      x2(nfac)=x2(nfac)/dh(ij)
      np=nfac+1
      do nip=2,nfac
         i=np-nip
         ii=ij-nip
         v=x2(i)/dh(ii)
         ip=i+1
         ij=ii
         do j=ip,nfac
            ii=ii+1
            v=v-dh(ii)*x2(j)
         end do
         x2(i)=v
      end do
412   continue
      if(ir.eq.nfac)go to 660
      indqn=7
      if(iter.eq.1)indqn=-6
      return
660   continue
      do i=1,n
         i1=indic(i)
         dir(i)=-g(i)*scal
         if(i1.le.nfac) dir(i)=-x2(i1)
      end do
      continue
c
c     gestion contraintes actives (si iact=1)
      if(iact.ne.1)go to 675
      do i=1,n
         if(izig(i).gt.0)dir(i)=0.
         if(indic(i).gt.nfac)dir(i)=0.0d+0
      end do
675   continue
c
c     recherche lineaire
c     conservation de x et g . calcul de dir+ et fpn
      do i=1,n
         g1(i)=g(i)
         x1(i)=x(i)
      end do
c     ifp =1 si fpn trop petit. on prend alors d=-g
      ifp=0
      fn=f
709   fpn=0.0d+0
      do i=1,n
         if(x(i)-binf(i).le.epsx(i).and.dir(i).lt.0.)dir(i)=0.0d+0
         if(bsup(i)-x(i).le.epsx(i).and.dir(i).gt.0.)dir(i)=0.0d+0
         fpn=fpn + g(i)*dir(i)
      end do
      if(fpn.gt.0.0d+0) then
         if(ifp.eq.1) then
c$$$            if(iprint.gt.0) then
c$$$              write(bufstr,1705) fpn
c$$$              call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$              endif
c$$$1705        format(' qnbd : arret fpn non negatif=',d11.4)
            indqn=6
            if(iter.eq.1)indqn=-3
c$$$            if(iprint.gt.0) then
c$$$              write(bufstr,123)indqn
c$$$              call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$              endif
            return
         else
            ifp=1
            do i=1,n
               if(izig(i).gt.0)dir(i)=-scal*g(i)
            end do
            irit=1
            go to 709
         endif
      endif
c     calcul du t initial suivant une idee de fletcher
      t1=t
      if(iter.eq.1) diff=df0
      t=-2.0d+0*diff/fpn
      if(t.gt.0.30d+0.and.t.lt.3.0d+0)t=1.0d+0
      if(eps1.lt.eps0)t=1.0d+0
      if(indqn.eq.2)t=1.0d+0
      if(iter.gt.1.and.t1.gt.0.010d+0.and.t1.lt.100.0d+0)t=1.0d+0
      tmax=1.0d+10
      t=min(t,tmax)
      t=max(t,10.*zero)
c     amd,amf tests sur h'(t) et diff
      amd=.7
      amf=.1
      napm=15
      napm1=nap + napm
      if(napm1.gt.napmax)napm1=napmax
      call rlbd(indrl,n,simul,x,binf,bsup,fn,fpn,t,tmax,dir,g,
     &     tproj,amd,amf,zero,nap,napm1,x2,izs,rzs,dzs)
      if(indrl.ge.10)then
         indsim=4
         nap=nap + 1
         call simul(indsim,n,x,f,g,izs,rzs,dzs)
         if(indsim.le.0)then
            indqn=-3
            if(indsim.eq.0)indqn=0
c$$$            if(iprint.gt.0) then
c$$$              write(bufstr,123)indqn
c$$$              call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$              endif
            return
         endif
      endif
      if(indrl.le.0)then
         indqn=10
         if(indrl.eq.0)indqn=0
         if(indrl.eq.-3)indqn=13
         if(indrl.eq.-4)indqn=12
         if(indrl.le.-1000)indqn=11
c$$$         if(iprint.gt.0) then
c$$$           write(bufstr,123)indqn
c$$$           call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$           endif
         return
      endif
c
      if(nap.lt.napmax)go to 758
      f=fn
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,755)napmax
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$755   format(' qnbd : retour cause max appels simul',i9)
      indqn=4
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
      return
758   continue
c     section 8 test de convergence
c
      do i=1,n
         if(abs(x(i)-x1(i)).gt.epsx(i))go to 806
      end do
      f=fn
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,1805)
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$1805  format(' qnbd : retour apres convergence de x')
      indqn=3
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
      return
806   continue
      difg=0.0d+0
      do i=1,n
         aa=g(i)
         if(x(i)-binf(i).le.epsx(i))aa=min(0.0d+0,aa)
         if(bsup(i)-x(i).le.epsx(i))aa=max(0.0d+0,aa)
         difg=difg + aa**2
      end do
      difg1=0.0d+0
      do i=1,n
         if(indic(i).gt.nfac)go to 820
         aa=g(i)
         if(x(i)-binf(i).le.epsx(i))aa=min(0.0d+0,aa)
         if(bsup(i)-x(i).le.epsx(i))aa=max(0.0d+0,aa)
         difg1=difg1 + aa**2
      end do
820   continue
      difg1=sqrt(difg1)
      difg=sqrt(difg)
      difg=difg/sqrt(real(n))
      diff=abs(f-fn)
      df0=-diff
      if(irit.eq.1)difg0=difg1
      f=fn
c$$$      if(iprint.ge.2) then
c$$$         write(bufstr,860)epsg,difg,epsf,diff,nap
c$$$         call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$         endif
c$$$860   format(' qnbd : epsg,difg=',2d11.4,'  epsf,diff=',2d11.4
c$$$     &,'  nap=',i3)
      if(diff.lt.epsf)then
      indqn=2
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,1865)diff
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$1865  format(' qnbd : retour cause decroissance f trop petite=',d11.4)
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
      return
      endif
      if(difg.gt.epsg)go to 200
      indqn=1
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,1900)difg
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
c$$$1900  format(' qnbd : retour cause gradient projete petit=',d11.4)
c$$$      if(iprint.gt.0) then
c$$$        write(bufstr,123)indqn
c$$$        call basout(io_out ,io ,bufstr(1:lnblnk(bufstr)))
c$$$        endif
      return
      end
