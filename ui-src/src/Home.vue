<template>
  <!-- 主体列表 -->
  <van-empty image="network"
    :description="moduleInfo.serviceState ? t('common.service_running') : t('common.service_no_run')">
    <van-button round type="primary" class="bottom-button" @click="startService"
      :color="moduleInfo.serviceState ? 'linear-gradient(to right, #ff6034, #ee0a24)' : '#1989FA'">
      {{ !moduleInfo.serviceState ? t('common.service_start') : t('common.service_stop') }}</van-button>
  </van-empty>
  <van-field v-model="runModeName" is-link readonly :label="$t('common.run_mode')"
    :placeholder="t('network.default_run_mode_tips')" @click="showRunModePicker = true"
    :disabled="moduleInfo.serviceState" />
  <van-popup v-model:show="showRunModePicker" destroy-on-close position="bottom">
    <van-picker :columns="runModeOption" v-model="selectedRunModeValues" @confirm="onRunModeConfirm"
      @cancel="showRunModePicker = false" />
  </van-popup>
  <!-- 命令行模式 -->
  <div v-show="commandObj.runMode == 'command'">
    <van-cell-group inset :title="t('common.base_settings')">
      <van-field v-model="commandObj.networkName" :label="t('network.networkName')" :disabled="moduleInfo.serviceState"
        required />
      <van-field v-model="commandObj.networkPassWd" :label="t('network.network_secret')"
        :disabled="moduleInfo.serviceState" required />
      <van-field :label="t('network.virtual_ipv4_dhcp')" input-align="right">
        <template #input>
          <van-switch v-model="commandObj.dhcpEnable" :disabled="moduleInfo.serviceState" />
        </template>
      </van-field>
      <van-field v-model="commandObj.virtual_ipv4" :label="t('network.virtual_ipv4')" placeholder="10.0.0.1/24"
        :rules="[{ validator: validatorMessage }]" :disabled="commandObj.dhcpEnable" />
      <van-field v-model="commandObj.peer_urls" :label="t('network.peer_urls')" placeholder="初始连接的对等节点, -p 参数"
        :rules="[{ validator: validatorMessage }]" :disabled="moduleInfo.serviceState" />
    </van-cell-group>
  </div>
  <!-- web模式 -->
  <div v-show="commandObj.runMode == 'web'">
    <van-cell-group inset :title="t('network.webMode')">
      <van-field v-model="commandObj.webServer" :label="t('network.webServer')" placeholder=""
        :disabled="moduleInfo.serviceState" :rules="[{ validator: validatorMessage }]" />
      <van-field :label="t('network.local_web')" input-align="right">
        <template #input>
          <van-switch @change="moduleInfo.changePrivateDeployment" v-model="commandObj.privateDeployment"
            :disabled="moduleInfo.serviceState" />
        </template>
      </van-field>
      <!-- web私有化 -->
      <van-field v-show="commandObj.privateDeployment" v-model="commandObj.webListenPort" type="digit" label="web监听端口"
        placeholder="22020" maxlength="5" :disabled="moduleInfo.serviceState" />
      <van-field v-show="commandObj.privateDeployment" v-model="commandObj.webRestfulPort" type="digit"
        label="restful端口" placeholder="11211" maxlength="5" :disabled="moduleInfo.serviceState" />
      <van-field v-show="commandObj.privateDeployment" v-model="commandObj.webListenProtocol" is-link readonly
        label="监听协议" :disabled="moduleInfo.serviceState" @click="showPicker3 = true" />
    </van-cell-group>
  </div>
  <!-- 配置文件模式 -->
  <div v-show="commandObj.runMode == 'file'">
    <van-cell-group inset :title="t('network.fileMode')">
      <van-cell center title="操作">
        <template #right-icon>
          <van-button type="primary" size="mini" icon="replay" plain
            @click="router.push('/manage/config')">配置助手</van-button>
          <van-button type="primary" size="mini" icon="replay" plain @click="reload()">重载配置</van-button>
          <van-button type="primary" size="mini" icon="plus" plain @click="update()">保存配置</van-button>
        </template>
      </van-cell>
      <codemirror v-model="commandObj.conf" :style="{ height: '50vh' }" :tabSize="2" placeholder="Toml"
        :extensions="extensions" :autofocus="true" :indent-with-tab="true" :disabled="moduleInfo.serviceState"
        @blur="changeCall" />
    </van-cell-group>
  </div>
  <van-cell-group inset :title="t('common.advanced_settings')">
    <div v-show="commandObj.runMode == 'command'">
      <van-field v-model="commandObj.external_node" :label="t('network.external_node')"
        placeholder="使用公共共享节点来发现对等节点, -e 参数" :rules="[{ validator: validatorMessage }]"
        :disabled="moduleInfo.serviceState" />
      <van-field v-model="commandObj.hostName" :label="t('network.hostName')" :placeholder="t('network.hostName')"
        :disabled="moduleInfo.serviceState" />

      <van-collapse v-model="activeNames">
        <van-collapse-item :title="t('network.proxy_cidrs')" name="1">
          <template #value>
            <van-tag plain type="primary" v-for="(route2, ridx2) in commandObj.proxy_cidrs" :key="ridx2">
              {{ route2 }}
            </van-tag>
            <van-tag plain type="primary" v-show="commandObj.proxy_cidrs.length === 0">
              {{ t('network.addSubRouteTips') }}
            </van-tag>

          </template>
          <van-cell title="" center>
            <template #value>
              <van-button type="success" size="small" @click="commandObj.proxy_cidrs.push('')"
                :disabled="moduleInfo.serviceState">
                {{ t('networkDetail.addRouteRule') }}
              </van-button>
            </template>
          </van-cell>
          <van-field v-for="(route, ridx) in commandObj.proxy_cidrs" :key="ridx" v-model="commandObj.proxy_cidrs[ridx]"
            clearable placeholder="192.168.0.0/23">
            <template #button>
              <van-icon name="delete-o" color="#1989fa" size="1.2rem" @click="commandObj.proxy_cidrs.splice(ridx, 1)" />
            </template>
          </van-field>
        </van-collapse-item>
        <van-collapse-item :title="t('network.flags_switch')" name="2">
          <van-checkbox-group v-model="checked" direction="horizontal" shape="square" @change="checkAllChange">
            <van-cell v-for="(item, index) in textMap.advanced" clickable :key="item" :title="item.title"
              :label="item.label" @click="commandObj.value.advance[index].toggle()">
              <template #right-icon>
                <van-checkbox :name="item.name" @click.stop />
              </template>
            </van-cell>
          </van-checkbox-group>
        </van-collapse-item>
      </van-collapse>
      <van-field v-model="compressionAlgorithm" is-link readonly :label="t('network.compressionAlgorithm')"
        :disabled="moduleInfo.serviceState" :placeholder="t('common.default')"
        @click="showCompressionAlgorithmPicker = true" />
      <van-popup v-model:show="showCompressionAlgorithmPicker" destroy-on-close position="bottom">
        <van-picker :columns="compressionAlgorithmOption" @confirm="onCompressionAlgorithmConfirm"
          @cancel="showCompressionAlgorithmPicker = false" />
      </van-popup>
      <van-field v-model="commandObj.rpcPort" :label="t('network.rpc_port')" placeholder="15888" type="digit"
        maxlength="5" :disabled="moduleInfo.serviceState" />
      <van-field v-model="commandObj.tunName" :label="t('network.tun_name')" placeholder="留空自动生成"
        :disabled="moduleInfo.serviceState" />
      <van-field :label="t('network.listenIPv6')" input-align="right">
        <template #input>
          <van-switch v-model="commandObj.listenIPv6" :disabled="moduleInfo.serviceState" />
        </template>
      </van-field>

    </div>

    <div>
      <van-field v-model="loggin" is-link readonly :label="t('common.logging')" :placeholder="t('common.close')"
        :disabled="moduleInfo.serviceState" @click="showLogginPicker = true" />
      <van-field v-model="listen" is-link readonly :label="t('network.listenPort')" placeholder="不监听"
        :disabled="moduleInfo.serviceState" @click="showPicker2 = true" />
      <div v-show="commandObj.listen == 'true'">

        <van-field v-model="commandObj.tcpPort" type="digit" :label="t('network.listenTCPort')" maxlength="5"
          placeholder="11010,写0不监听" :disabled="moduleInfo.serviceState" @blur="updateListenPort" />
        <van-field v-model="commandObj.udpPort" type="digit" :label="t('network.listenUDPort')" maxlength="5"
          placeholder="11010,写0不监听" :disabled="moduleInfo.serviceState" @blur="updateListenPort" />
        <van-field v-model="commandObj.wsPort" type="digit" :label="t('network.listenWSPort')" maxlength="5"
          placeholder="11011,写0不监听" :disabled="moduleInfo.serviceState" @blur="updateListenPort" />
        <van-field v-model="commandObj.wgPort" type="digit" :label="t('network.listenWGPort')" maxlength="5"
          placeholder="11011,写0不监听" :disabled="moduleInfo.serviceState" @blur="updateListenPort" />
        <van-field v-model="commandObj.wssPort" type="digit" :label="t('network.listenWSSPort')"
          placeholder="11012,写0不监听" :disabled="moduleInfo.serviceState" @blur="updateListenPort" maxlength="5" />
      </div>
    </div>
  </van-cell-group>
  <van-popup v-model:show="showLogginPicker" destroy-on-close position="bottom">
    <van-picker :columns="logLevel" @confirm="onLogginConfirm" @cancel="showLogginPicker = false" />
  </van-popup>
  <van-popup v-model:show="showPicker2" destroy-on-close position="bottom">
    <van-picker :columns="listenOption" v-model="selectedListenValues" @confirm="onListenConfirm"
      @cancel="showPicker2 = false" />
  </van-popup>
  <van-popup v-model:show="showPicker3" destroy-on-close position="bottom">
    <van-picker :columns="protocolOption" v-model="selectedProtocolValues" @confirm="onProtocolConfirm"
      @cancel="showPicker3 = false" />
  </van-popup>
</template>
<script setup>
const props = defineProps({
  theme: Boolean
})
//接收父组件传来的值
console.info(`theme:${props.theme}`)
import { onMounted, ref, computed } from 'vue';
import { MODDIR, ETPATH, execCmd, spawnCmdWithCallback,execCmdWithCallback,getCorePath, getWebPath, isValidIpv4Subnet, isValidPort, isEmpty, logDir, saveFile, readFile } from './tools'
import { useModuleInfoStore } from './stores/status'
import { useI18n } from './locales'; // 导入所有翻译信息
import { Codemirror } from "vue-codemirror";
import { StreamLanguage } from "@codemirror/language"
import { toml } from "@codemirror/legacy-modes/mode/toml"
import { oneDark } from "@codemirror/theme-one-dark"
import { parse as tomlParse, stringify as tomlStringify } from '@iarna/toml';
const router = useRouter()
const { t } = useI18n();
const moduleInfo = useModuleInfoStore();
const checked = ref([]);
const listen = ref('');
const dhcpEnable = ref(false);
const ready = ref(false);
const activeNames = ref(['']);

let runModeOption = [];
let listenOption = [];
let protocolOption = [];
let compressionAlgorithmOption = [];
let logLevel = [];

const selectedRunModeValues = ref(['command']);
const selectedListenValues = ref(['false']);
const selectedProtocolValues = ref(['udp']);

const validatorMessage = (val) => `${val} 不合法，请重新输入`;
const showRunModePicker = ref(false);
const showCompressionAlgorithmPicker = ref(false);
const showLogginPicker = ref(false);
const showPicker2 = ref(false);
const showPicker3 = ref(false);
const runModeName = ref('');
const compressionAlgorithm = ref('');
const loggin = ref('');
const commandObj = ref({
  'runMode': 'web',
  'networkName': '',
  'networkPassWd': '',
  'dhcpEnable': true,
  'virtual_ipv4': '10.0.0.2/24',
  'peer_urls': 'tcp://public.easytier.top:11010',
  'external_node': '',
  'proxy_cidrs': [],
  'listen': false,
  'hostName': 'easytierForKSU',
  'compressionAlgorithm': 'none',
  'logLevel': 'off',
  'rpcPort': 15888,
  'tcpPort': 11010,
  'udpPort': 11010,
  'wsPort': 11011,
  'wgPort': 11011,
  'wssPort': 11012,
  'tunName': '',
  'advance': [],
  'conf': `instance_name = "default"
dhcp = true
listeners = []
exit_nodes = []
rpc_portal = "0.0.0.0:15888"

[network_identity]
network_name = "mynetwork"
network_secret = "mysecret"

[[peer]]
uri = "tcp://public.easytier.top:11010"

[flags]
enable_kcp_proxy = true

[file_logger]
level = "info"
dir = "${logDir}"
`,
  'webServer': '',
  'privateDeployment': false,
  'listenIPv6': false,
  'webListenProtocol': 'UDP',
  'webListenPort': 22020,
  'webRestfulPort': 11211

});
// TODO 国际化
const textMap = {
  "runModeOption": {
    "command": '命令行',
    "file": '配置文件',
    "web": 'WEB配置'
  },
  "listenOption": {
    'true': '启用监听',
    'false': '不监听'
  },
  "protocolOption": {
    'TCP': 'TCP',
    'UDP': 'UDP'
  },
  "compressionAlgorithmOption": {
    "none": '默认',
    "zstd": 'zstd'
  },
  "logLevel": {
    "off": '关闭',
    "trace": '跟踪',
    "info": '信息',
    "debug": '调试',
    "warn": '警告',
    "error": '错误'
  },
  "advanced": [
    {
      "name": "disableEncryption",
      "title": t('network.disableEncryption'),
      "label": "禁用对等节点通信的加密，若关闭加密则其他节点也必须关闭加密"
    },
    {
      "name": "disableP2P",
      "title": t('network.disable_p2p'),
      "label": "禁用P2P通信，只通过-p指定的节点转发数据包"
    },
    {
      "name": "enableKCPProxy",
      "title": t('network.enable_kcp_proxy'),
      "label": "将TCP流量转为 KCP 流量，降低传输延迟，提升传输速度"
    },
    {
      "name": "disableUdpHolePunching",
      "title": t('network.disableUdpHolePunching'),
      "label": "禁用UDP打洞功能"
    },
    {
      "name": "disableKCPInput",
      "title": t('network.disable_kcp_input'),
      "label": "不允许其他节点使用 KCP 代理 TCP 流到此节点。开启 KCP 代理的节点访问此节点时，依然使用原始"
    },
    {
      "name": "noTun",
      "title": t('network.no_tun'),
      "label": "不创建TUN设备，可以使用子网代理访问节点"
    },
    {
      "name": "multiThread",
      "title": t('network.multiThread'),
      "label": "使用多线程运行时，默认为单线程"
    },
    {
      "name": "latencyFirst",
      "title": t('network.latencyFirst'),
      "label": "延迟优先模式，将尝试使用最低延迟路径转发流量，默认使用最短路径"
    },
    {
      "name": "useSmoltcp",
      "title": t('network.use_smoltcp'),
      "label": "为子网代理启用smoltcp堆栈"
    }
  ]

}
// ======== method=========
const checkAllChange = (val) => {
  commandObj.value.advance = checked.value;
}
//填充参数
const fillOptions = () => {
  for (const key in textMap) {
    const obj = textMap[key];
    for (const k in obj) {
      if (key == 'runModeOption') {
        runModeOption.push({ text: obj[k], value: k });
      } else if (key == 'listenOption') {
        listenOption.push({ text: obj[k], value: k });
      } else if (key == 'compressionAlgorithmOption') {
        compressionAlgorithmOption.push({ text: obj[k], value: k });
      } else if (key == 'logLevel') {
        logLevel.push({ text: obj[k], value: k });
      } else if (key == 'protocolOption') {
        protocolOption.push({ text: obj[k], value: k });
      }
    }
  }
  runModeName.value = textMap.runModeOption[commandObj.value.runMode];
  listen.value = textMap.listenOption[commandObj.value.listen];
  compressionAlgorithm.value = textMap.compressionAlgorithmOption[commandObj.value.compressionAlgorithm];
  loggin.value = textMap.logLevel[commandObj.value.logLevel];
}
// vue-codemirror 插件
const extensions = computed(() => {
  const result = [StreamLanguage.define(toml)]
  if (!props.theme) {
    result.push(oneDark)
  }
  return result
})
//编辑器回调，更新程序日志和端口信息，用于更新防火墙
const changeCall = () => {
  try {
    let conf = tomlParse(commandObj.value.conf);
    //更新端口信息，用于放行防火墙
    if (conf.listeners.length > 0) {
      //重置为0，不监听
      commandObj.value.tcpPort = 0;
      commandObj.value.udpPort = 0;
      commandObj.value.wssPort = 0;
      commandObj.value.wsPort = 0;
      commandObj.value.wgPort = 0;
      commandObj.value.listen = 'true';
      conf.listeners.forEach(element => {
        if (element.indexOf('tcp') > -1) {
          commandObj.value.tcpPort = element.split(':')[2];
        } else if (element.indexOf('udp') > -1) {
          commandObj.value.udpPort = element.split(':')[2];
        } else if (element.indexOf('wss') > -1) {
          commandObj.value.wssPort = element.split(':')[2];
        } else if (element.indexOf('ws') > -1) {
          commandObj.value.wsPort = element.split(':')[2];
        } else if (element.indexOf('wg') > -1) {
          commandObj.value.wgPort = element.split(':')[2];
        }
      });
    } else {
      commandObj.value.listen = 'false';
    }
    listen.value = textMap.listenOption[commandObj.value.listen];
    onListenConfirm({ selectedValues: [commandObj.value.listen] })
    //更新日志信息
    if (conf.file_logger) {
      commandObj.value.logLevel = conf.file_logger.level;
    } else {
      conf.file_logger = {};
      conf.file_logger['level'] = commandObj.value.logLevel;
    }
    conf.file_logger['dir'] = `${logDir}`;
    loggin.value = textMap.logLevel[commandObj.value.logLevel];
    onLogginConfirm({ selectedValues: [commandObj.value.logLevel] })
    //更新配置文件
    commandObj.value.conf = tomlStringify(conf);
  } catch (error) {
    console.error(error)
  }
  console.info('编辑器回调')
}
// 监听端口回调
// 分别监听端口并根据输入的值回显到conf中，格式为协议://0.0.0.0:port
const updateListenPort = (value) => {
  console.info('端口回调')
  if (commandObj.value.listen == 'false') { }
  let conf = tomlParse(commandObj.value.conf);
  conf.listeners = [];
  if (isValidPort(commandObj.value.wssPort)) {
    conf.listeners.push(`wss://0.0.0.0:${commandObj.value.wssPort}`)
  }
  if (isValidPort(commandObj.value.udpPort)) {
    conf.listeners.push(`udp://0.0.0.0:${commandObj.value.udpPort}`)
  }
  if (isValidPort(commandObj.value.tcpPort)) {
    conf.listeners.push(`tcp://0.0.0.0:${commandObj.value.tcpPort}`)
  }
  if (isValidPort(commandObj.value.wsPort)) {
    conf.listeners.push(`ws://0.0.0.0:${commandObj.value.wsPort}`)
  }
  if (isValidPort(commandObj.value.wgPort)) {
    conf.listeners.push(`wg://0.0.0.0:${commandObj.value.wgPort}`)
  }
  commandObj.value.conf = tomlStringify(conf);
}
onMounted(() => {
  console.info(`服务状态：${moduleInfo.serviceState}`)
  readFile()
  // init()
  fillOptions();
})

const onRunModeConfirm = ({ selectedValues }) => {
  commandObj.value.runMode = selectedValues.join(',');
  runModeName.value = textMap.runModeOption[selectedValues.join(',')];
  showRunModePicker.value = false;
  moduleInfo.runMode = selectedValues.join(',');
};
const onListenConfirm = ({ selectedValues }) => {
  commandObj.value.listen = selectedValues.join(',');
  listen.value = textMap.listenOption[selectedValues.join(',')];
  showPicker2.value = false;
};
const onProtocolConfirm = ({ selectedValues }) => {
  commandObj.value.webListenProtocol = selectedValues.join(',');
  // protocol.value = textMap.protocolOption[selectedValues.join(',')];
  showPicker3.value = false;
};
const onLogginConfirm = ({ selectedValues }) => {
  commandObj.value.logLevel = selectedValues.join(',');
  loggin.value = textMap.logLevel[selectedValues.join(',')];
  if (commandObj.value.runMode == 'file') {
    let conf = tomlParse(commandObj.value.conf);
    conf.file_logger = {};
    conf.file_logger['level'] = commandObj.value.logLevel;
    conf.file_logger['dir'] = `${logDir}`;
    commandObj.value.conf = tomlStringify(conf);
  }
  showLogginPicker.value = false;
};
const onCompressionAlgorithmConfirm = ({ selectedValues }) => {
  commandObj.value.compressionAlgorithm = selectedValues.join(',');
  compressionAlgorithm.value = textMap.compressionAlgorithmOption[selectedValues.join(',')];
  showCompressionAlgorithmPicker.value = false;
};
// 监听端口
const addPortToCommandArgs = (commandArgs, port, protocol) => {
  if (isValidPort(port)) {
    commandArgs += ` -l ${protocol}:${port} `;
  }
  return commandArgs;
}
/**
 * 检查已填报的内容，并返回命令行参数
 * @param {string} runMode 运行模式
 * @returns {string} 命令行参数
 */
const checkContent = (runMode) => {
  let commandArgs = `${getCorePath()} `
  if (runMode === 'command') {
    //设置网络名称
    if (isEmpty(commandObj.value.networkName)) {
      showNotify({
        type: 'danger',
        message: t('network.networkName_empty')
      });
      return;
    } else {
      commandArgs += ` --network-name ${commandObj.value.networkName}`
    }
    //设置网络密码
    if (isEmpty(commandObj.value.networkPassWd)) {
      showNotify({
        type: 'warning',
        message: t('network.networkPassWd_empty_warn')
      });
    } else {
      commandArgs += ` --network-secret ${commandObj.value.networkPassWd}`
    }
    //DHCP和虚拟IP地址
    if (commandObj.value.dhcpEnable) {
      commandArgs += ' -d'
    } else if (!isEmpty(commandObj.value.virtual_ipv4) && !isValidIpv4Subnet(commandObj.value.virtual_ipv4)) {
      showNotify({
        type: 'danger',
        message: t('network.virtual_ipv4_error')
      });
      return;
    } else {
      commandArgs += ' -i ' + commandObj.value.virtual_ipv4
    }
    //对等节点
    if (!isEmpty(commandObj.value.peer_urls)) {
      commandArgs += ' -p ' + commandObj.value.peer_urls
    }

    //共享节点
    if (!isEmpty(commandObj.value.external_node)) {
      commandArgs += ' -e ' + commandObj.value.external_node
    }

    //子网代理
    if (commandObj.value.proxy_cidrs.length > 1) {
      for (let i = 0; i < commandObj.value.proxy_cidrs.length; i++) {
        if (isValidIpv4Subnet(commandObj.value.proxy_cidrs[i])) {
          showNotify({
            type: 'danger',
            message: t('network.proxy_cidrs_error')
          });
          return;
        } else {
          commandArgs += ` -n ${commandObj.value.proxy_cidrs[i]} `
        }
      }
    }
    //监听端口
    if (commandObj.value.listen === 'true') {
      // 如果启用监听，使用默认端口
      addPortToCommandArgs(commandArgs, commandObj.value.tcpPort, 'tcp');
      addPortToCommandArgs(commandArgs, commandObj.value.udpPort, 'udp');
      addPortToCommandArgs(commandArgs, commandObj.value.wssPort, 'wss');
      addPortToCommandArgs(commandArgs, commandObj.value.wsPort, 'ws');
      addPortToCommandArgs(commandArgs, commandObj.value.wgPort, 'wg');
    } else if (commandObj.value.listen === 'false') {
      // 不监听
      commandArgs += ' --no-listener'
    }
    // 监听IPv6
    if (!commandObj.value.listenIPv6) {
      commandArgs += ' --disable-ipv6'
    }
    //主机名
    if (!isEmpty(commandObj.value.hostName)) {
      commandArgs += ` --hostname ${commandObj.value.hostName} `
    }
    //压缩算法
    if (commandObj.value.compressionAlgorithm !== 'none') {
      commandArgs += ` --compression ${commandObj.value.compressionAlgorithm} `
    }
    // 日志级别
    if (!isEmpty(commandObj.value.logLevel)) {
      commandArgs += ` --file-log-level ${commandObj.value.logLevel} `
    }
    commandArgs += ` --file-log-dir ${logDir} `
    //RPC门户端口
    if (!isEmpty(commandObj.value.rpcPort)) {
      commandObj.value.rpcPort = 15888;
    } else if (!isValidPort(commandObj.value.rpcPort)) {
      showNotify({
        type: 'danger',
        message: t('network.rpcPort_error')
      });
      return;
    }
    commandArgs += ` --rpc-portal ${commandObj.value.rpcPort} `
    //tun设备名称
    if (!isEmpty(commandObj.value.tunName)) {
      commandArgs += ` --dev-name ${commandObj.value.tunName} `
    }
    // advance
    if (commandObj.value.advance.length > 0) {
      commandObj.value.advance.forEach(item => {
        switch (item) {
          case "disableEncryption":
            commandArgs += ' --disable-encryption '
            break;
          case "disableP2P":
            commandArgs += ' --disable-p2p '
            break;
          case "enableKCPProxy":
            commandArgs += ' --enable-kcp-proxy '
            break;
          case "disableUdpHolePunching":
            commandArgs += ' --disable-udp-hole-punching '
            break;
          case "disableKCPInput":
            commandArgs += ' --disable-kcp-input '
            break;
          case "noTun":
            commandArgs += ' --no-tun '
            break;
          case "multiThread":
            commandArgs += ' --multi-thread '
            break;
          case "latencyFirst":
            commandArgs += ' --latency-first '
            break;
          case "useSmoltcp":
            commandArgs += ' --use-smoltcp '
            break;
          default:
            break;
        }
      });
    }
  } else if (runMode === 'file') {
    if (isEmpty(commandObj.value.conf)) {
      showNotify({
        type: 'danger',
        message: t('network.conf_empty')
      });
      return;
    }
    saveFile(commandObj.value.conf, `${MODDIR}/config.toml`);
    commandArgs += ` -c ${ETPATH}/config.toml `
  } else if (runMode === 'web') {
    if (isEmpty(commandObj.value.webServer)) {
      showNotify({
        type: 'danger',
        message: t('network.webServer_empty')
      });
      return;
    }
    commandArgs += ` -w ${commandObj.value.webServer} `
    if (commandObj.value.privateDeployment) {
      if (isValidPort(commandObj.value.webListenPort)) {
        commandObj.value.webListenPort = 22020;
      }
      if (isValidPort(commandObj.value.webRestfulPort)) {
        commandObj.value.webListenPort = 11211;
      }
      let webArgs = `${getWebPath()} --file-log-level ${commandObj.value.logLevel} --console-log-level ${commandObj.value.logLevel} --file-log-dir ${logDir} --config-server-port ${commandObj.value.webListenPort} --api-server-port ${commandObj.value.webRestfulPort} --config-server-protocol=${commandObj.value.webListenProtocol.toLowerCase()} `
      commandArgs = `${webArgs} && ${commandArgs}`
    }
  } else {
    showNotify({
      type: 'danger',
      message: t('network.runMode_error')
    });
    return;
  }
  return commandArgs;

};// 启动服务
const startService = () => {
  const cmdLine = checkContent(commandObj.value.runMode);
  if (cmdLine) {
    console.info(`启动命令：${cmdLine}`)
    saveFile(JSON.stringify(commandObj.value), `${ETPATH}/config.json`);
    saveFile(cmdLine, `${ETPATH}/cmdLine`);
    moduleInfo.serviceState = !moduleInfo.serviceState;
    //TODO 调用启动脚本
  }
}

const init = () => {
  console.info('init')
  showLoadingToast({
    duration: 0,
    message: '',
    forbidClick: true,
    loadingType: 'spinner',
  });
  try {
    execCmdWithCallback({
      cmd: `sh ${MODDIR}/api.sh status`,
      onSuccess: (data) => {
        const configFile = JSON.parse(readFile(`${ETPATH}/config.json`))
        commandObj.value = configFile;
      }, onError: (data) => {
      }
    })
    
  } catch (error) {
    console.error('配置文件加载异常', error)
  }finally{
    closeToast()
  }

}


</script>

<style></style>