/** @param {Uint8Array} data */
export function imageType(data){
 if(data.length>=3&&data[0]===255&&data[1]===216&&data[2]===255)return 'image/jpeg';
 if(data.length>=8&&[137,80,78,71,13,10,26,10].every((n,i)=>data[i]===n))return 'image/png';
 if(data.length>=12&&new TextDecoder().decode(data.slice(0,4))==='RIFF'&&new TextDecoder().decode(data.slice(8,12))==='WEBP')return 'image/webp';
 return null;
}
