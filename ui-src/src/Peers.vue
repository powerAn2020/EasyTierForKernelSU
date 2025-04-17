<template>

  <van-row justify="center">
    <van-col >
      <van-checkbox-group v-model="checked" direction="horizontal">
        <van-checkbox name="moreInfo">详细模式</van-checkbox>
        <van-checkbox name="autoRefesh">自动刷新</van-checkbox>
      </van-checkbox-group>
    </van-col>
  </van-row>
  <van-cell-group inset :title="item.hostname" v-for="(item, index) in tableData" :key="index">
    <van-cell title="IP" :value="item.ipv4" />
    <van-cell title="⬆上行流量" :value="item.tx_bytes" />
    <van-cell title="⬇下行流量" :value="item.rx_bytes" />
    <van-cell title="穿透方式" :value="item.cost" v-show="show"/>
    <van-cell title="Nat类型" :value="item.nat_type" v-show="show"/>
    <van-cell title="隧道类型" :value="item.tunnel_proto" v-show="show"/>
    <van-cell title="丢包率" :value="item.loss_rate" v-show="show"/>
    <van-cell title="延迟" :value="item.lat_ms" v-show="show"/>
    <van-cell title="版本" :value="item.version" v-show="show"/>
  </van-cell-group>

</template>

<script setup>
// import { reactive, ref } from 'vue';
import { ETPATH, MODDIR, execCmd } from './tools'
import { useModuleInfoStore } from './stores/status'
import { useI18n } from './locales'; // 导入所有翻译信息
const { t } = useI18n();
const moduleInfo = useModuleInfoStore();
const ready = ref(false);

const show = ref(false);
const moonId = ref('');
const loading = ref(false);

const items = reactive([])
const checked = ref([])

const tableData = [
  {
    ipv4: '10.0.0.3/24',
    hostname: 'LAPTOP-UGHK1ID3',
    cost: 'Local',
    lat_ms: '-',
    loss_rate: '-',
    rx_bytes: '-',
    tx_bytes: '-',
    tunnel_proto: '-',
    nat_type: 'PortRestricted',
    id: '1731809060',
    version: '2.2.2-dd5b00fa'
  },
  {
    ipv4: '',
    hostname: 'PublicServer_public.easytier.cn',
    cost: 'p2p',
    lat_ms: '46.552',
    loss_rate: '0.000',
    rx_bytes: '3.51 kB',
    tx_bytes: '51.67 kB',
    tunnel_proto: 'tcp',
    nat_type: 'Unknown',
    id: '1845661621',
    version: '2.2.4-e5917fad~'
  },
  {
    ipv4: '10.0.0.1/24',
    hostname: 'iStoreOS',
    cost: 'p2p',
    lat_ms: '11.286',
    loss_rate: '0.000',
    rx_bytes: '161.42 kB',
    tx_bytes: '480.75 kB',
    tunnel_proto: 'tcp,udp',
    nat_type: 'PortRestricted',
    id: '1118980178',
    version: '2.2.4-67100407'
  }
]
const onRefresh = () => {
  getList();
  setTimeout(() => {
    loading.value = false;
  }, 50);
};
const getContent = (arr) => {
  let showText = '';
  if (typeof arr != 'undefined' && arr != null) {
    let peerList = new Set();
    for (const path of arr) {
      let address = path.address;
      if (path.active && !peerList.has(address)) {
        peerList.add(address);
        showText += address;
        showText += '\n';
      }
    }
  } else {
    showText = '-'
  }
  return showText;
}
const addBtn = (action) =>
  new Promise((resolve) => {
    if (action === 'confirm') {
      execCmd(`sh ${MODDIR}/api.sh local orbit ${moonId.value}`).then(v => {
        resolve(true);
      })

    } else if (action === 'cancel') {
      resolve(true);
    }
  });
const getList = () => {
  execCmd(`sh ${MODDIR}/api.sh local peer`).then(v => {
    items.length = 0;
    items.push(...JSON.parse(v));
  })
}
let interval;
watch(() => checked.value, (New, Old) => {
  if(New.includes('moreInfo') && !Old.includes('moreInfo')){
    show.value=true
  }else if(!New.includes('moreInfo')){
    show.value=false
  }
  // 设置定时任务，每秒刷新一次，如果没有选中自动刷新则取消定时任务，如果重复选中则取消上一次任务重新启用
  if(New.includes('autoRefesh') && !Old.includes('autoRefesh')){
    interval=setInterval(()=>{
      console.info("定时刷新")
    },1000)
  }else if(!New.includes('autoRefesh')){
    clearInterval(interval);
  }
  console.debug(`新值:${New} ——— 老值:${Old}`)
})
onBeforeUnmount(() => {
  console.debug(`销毁页面->清除计时器`)
  clearInterval(interval);
});
const init = () => {
  console.info('init')
  showLoadingToast({
    duration: 0,
    message: '',
    forbidClick: true,
    loadingType: 'spinner',
  });
  let leaveNetwork = localStorage.getItem("EasytierForKSU.leaveNetwork");
  if (typeof leaveNetwork == "undefined" || leaveNetwork == null) {
    leaveNetwork = [];
    localStorage.setItem("EasytierForKSU.leaveNetwork", JSON.stringify(leaveNetwork));
  } else {
    leaveNetwork = JSON.parse(leaveNetwork);
  }
  setTimeout(() => {
    execCmd(`sh ${ETPATH}/zerotier.sh status`).then(v => {
      const statusObj = JSON.parse(v);
      if (statusObj.enable == "") {
        ready.value = false;
        moduleInfo.changeServiceState(false);
        // startServiceConfirm()
      } else {
        ready.value = true;
        moduleInfo.changeServiceState(true);
        getList();
      }
    });
    closeToast()
  }, 1000)
}
// init()

</script>