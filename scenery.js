/**
 * Mustache2 procedural environment polish.
 * All drawings are original Canvas 2D vector art; no external art or runtime dependencies.
 */
const colors = {
  warm: '#efc990', pale: '#fff0ce', ink: '#181c31', green: '#89b59d', wood: '#bf8f6b'
};
function fillRound(ctx,x,y,w,h,r,color) {
  ctx.beginPath(); ctx.roundRect(x,y,w,h,r); ctx.fillStyle=color;ctx.fill();
}
function circle(ctx,x,y,r,color) {
  ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fillStyle=color;ctx.fill();
}
export function drawFloorDetail(ctx,room,index) {
  ctx.save();
  ctx.beginPath();ctx.rect(room.x,room.y,room.w,room.h);ctx.clip();
  const {x,y,w,h}=room;
  if(index===0 || index===3 || index===5) {
    // Wood planks: organic variance without a repeating downloaded texture.
    ctx.lineWidth=2;
    for(let py=y+14;py<y+h;py+=29) {
      ctx.strokeStyle='#f9e8bf0b';
      ctx.beginPath();ctx.moveTo(x,py);ctx.lineTo(x+w,py);ctx.stroke();
      for(let px=x+((Math.floor(py/29)%2)*72)+54;px<x+w;px+=158) {
        ctx.strokeStyle='#10172919';ctx.beginPath();ctx.moveTo(px,py);ctx.lineTo(px,py+29);ctx.stroke();
      }
    }
  } else if(index===2) {
    // Kitchen: checkerboard stone.
    for(let py=y;py<y+h;py+=58)for(let px=x;px<x+w;px+=58){
      if(((Math.floor((py-y)/58)+Math.floor((px-x)/58))&1)===0){
        ctx.fillStyle='#ffffff08';ctx.fillRect(px+1,py+1,56,56);
      }
    }
  } else {
    ctx.strokeStyle='#c2b0c10c';ctx.lineWidth=1.5;
    for(let py=y+16;py<y+h;py+=42){ctx.beginPath();ctx.moveTo(x,py);ctx.lineTo(x+w,py);ctx.stroke();}
    for(let px=x+16;px<x+w;px+=42){ctx.beginPath();ctx.moveTo(px,y);ctx.lineTo(px,y+h);ctx.stroke();}
  }
  // Warm pools of indoor ceiling light.
  let lampX=x+w*.67,lampY=y+h*.58;
  const glow=ctx.createRadialGradient(lampX,lampY,4,lampX,lampY,235);
  glow.addColorStop(0,'#ffd5a312');glow.addColorStop(1,'#ffd5a300');
  ctx.fillStyle=glow;ctx.fillRect(x,y,w,h);
  // Understated perimeter board.
  ctx.strokeStyle='#f1d7aa19';ctx.lineWidth=6;ctx.strokeRect(x+3,y+3,w-6,h-6);
  ctx.restore();
}
function plant(ctx,x,y,scale=1) {
  ctx.save();ctx.translate(x,y);ctx.scale(scale,scale);
  ctx.fillStyle='#0005';ctx.beginPath();ctx.ellipse(4,8,26,10,0,0,Math.PI*2);ctx.fill();
  circle(ctx,0,0,23,'#b27c5d');circle(ctx,0,-2,17,'#614e42');
  for(let i=0;i<7;i++){
    const a=i*Math.PI*2/7;
    ctx.save();ctx.rotate(a);
    ctx.fillStyle=i%2?'#67998b':'#a6c69a';
    ctx.beginPath();ctx.ellipse(0,-14,9,19,0,0,Math.PI*2);ctx.fill();ctx.restore();
  }
  circle(ctx,0,0,6,'#bdd5a2');ctx.restore();
}
function lamp(ctx,x,y) {
  ctx.save();ctx.translate(x,y);
  ctx.fillStyle='#0005';ctx.beginPath();ctx.ellipse(3,8,19,7,0,0,Math.PI*2);ctx.fill();
  circle(ctx,0,0,19,'#9d8d8d');circle(ctx,0,0,13,colors.warm);circle(ctx,0,0,5,'#ffedbd');
  ctx.strokeStyle='#fff2d733';ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,0,30,0,Math.PI*2);ctx.stroke();
  ctx.restore();
}
function books(ctx,x,y) {
  ctx.save();ctx.translate(x,y);
  fillRound(ctx,-29,-17,58,35,5,'#342c40');
  for(let i=0;i<5;i++){
    const color=['#e3be80','#88a5aa','#cb809d','#c5a17c','#d9d6bb'][i];
    fillRound(ctx,-23+i*9,-11,7,24,1,color);
  }
  ctx.restore();
}
function picture(ctx,x,y) {
  ctx.save();ctx.translate(x,y);ctx.rotate(-.08);
  fillRound(ctx,-19,-24,38,48,4,'#ae8058');
  fillRound(ctx,-15,-20,30,40,2,'#30364e');
  ctx.fillStyle='#e9b28d';ctx.beginPath();ctx.moveTo(-11,9);ctx.lineTo(-2,-6);ctx.lineTo(5,4);ctx.lineTo(15,-3);ctx.lineTo(15,19);ctx.lineTo(-11,19);ctx.fill();
  circle(ctx,8,-10,4,'#f9d69b');ctx.restore();
}
export function drawSetDressing(ctx, now) {
  // Decorative, collision-free floor decals on room edges.
  plant(ctx,139,146,.8); plant(ctx,467,467,.76);
  plant(ctx,941,153,.77); plant(ctx,1075,468,.73);
  plant(ctx,141,891,.74); plant(ctx,945,886,.72);
  lamp(ctx,355,159); lamp(ctx,782,428); lamp(ctx,1310,460);
  books(ctx,890,861); books(ctx,835,215);
  picture(ctx,421,460); picture(ctx,1228,878);
  // A few tiny golden motes sparkle rather than overwhelming the pixel art.
  ctx.save();
  for(let i=0;i<12;i++){
    let x=145+(i*347)%1220,y=143+(i*229)%725;
    const alpha=.16+.14*(1+Math.sin(now*.8+i*1.3))*.5;
    circle(ctx,x,y,1.1+i%3*.25,'rgba(255,220,161,'+alpha+')');
  }
  ctx.restore();
}
