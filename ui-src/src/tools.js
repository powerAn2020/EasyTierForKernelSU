import { exec, spawn } from 'kernelsu';
import { Buffer } from 'buffer'
export const MODDIR = '/data/adb/modules/EasytierForKSU'
export const ETPATH = '/data/adb/easytier'

export const execCmd = async (cmd) => {
  console.info(cmd)
  const { errno, stdout, stderr } = await exec(cmd, { cwd: '/' })
  if (errno === 0) {
    // success
    console.log(stdout)
    return stdout
  } else {
    console.error(stderr)
  }
}
// console.info(moduleInfo())
export const execCmdWithErrno = async (cmd) => {
  console.info(cmd)
  const { errno, stdout, stderr } = await exec(cmd, { cwd: '/' });
  if (errno === 0) {
    // success
    console.log(stdout);
  } else {
    console.error(stderr)
  }
  return errno;
}

export const execCmdWithCallback = async ({ cmd, options = { cwd: '/' }, onSuccess, onError }) => {
  console.info(cmd)
  const { errno, stdout, stderr } = await exec(cmd, options);
  if (errno === 0) {
    console.log(stdout);
    // success
    if (onSuccess) {
      onSuccess(stdout);
    }
  } else {
    console.error(stderr)
    if (onError) {
      onError(stderr);
    }
  }
}

export const spawnCmdWithCallback = ({ cmd, args = [], onSuccess, onError }) => {
  console.info(cmd)
  const childProcess = spawn(cmd, args);
  childProcess.stdout.on('data', (data) => {
    console.log(data);
    if (onSuccess) {
      onSuccess(data);
    }
  });
  childProcess.stderr.on('data', (data) => {
    console.log(data);
    if (onError) {
      onError(data);
    }
  });
  childProcess.on('exit', (code) => {
    console.log(`child process exited with code ${code}`);
  });
};

export const readFile = async (filePath) => {
  return Buffer.from(await execCmd(`base64 -w 0 ${filePath}`), "base64").toString('utf-8');
}

export const saveFile = (content, filePath) => {
  return execCmd(`echo ${Buffer.from(content).toString("base64")} | base64 -d > ${filePath}`);
}

/**
  * 判断字符串是否为空 ,为空true，非空false
  * @param obj 
  * @returns 
  */
export const isEmpty = (obj) => {
  return typeof (obj) == "undefined" || obj == null || obj == "null" || obj.length == 0
}

export const getCorePath = () => {
  return ETPATH + "/bin/easytier-core"
}
/**
 * 校验IP/子网格式 
 * "192.168.10.0/24","192.168.10.0" 有效
 * "256.168.10.0/24",  // 无效 IP
 * "192.168.10.0/33",  // 无效子网掩码
 * @param {string} ipSubnet 
 * @returns 通过true，失败false
 */
export const isValidIpv4Subnet = (ipSubnet) => {
  if(!ipSubnet){
    return false;
  }
  const pattern = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/(3[0-2]|[1-2]?[0-9]))?$/;
  return pattern.test(ipSubnet);
}
/**
 * 校验端口号
 * @param {string} port 
 * @returns 
 */
export const isValidPort = (port) => {
  if(!port){
    return false;
  }
  const pattern = /^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/;
  return pattern.test(port);
}
export const logDir = ETPATH + '/log'