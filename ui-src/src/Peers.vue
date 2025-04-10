<template>
  <van-cell-group inset title="peer">
    <van-card v-for="(item, index) in tableData" :key="index" centered :title="item.hostname">
      <!-- <template #price>
          ⬆{{ item.tx_bytes }} ⬇{{ item.rx_bytes }}
        </template> -->
      <template #tags>
        <van-space direction="vertical" fill>
          <van-row>
            <van-col><van-tag plain type="primary">IP：{{ item.ipv4 }}</van-tag></van-col>
          </van-row>
          <van-row :gutter="[20, 20]" justify="space-between">
            <van-col>
              <van-tag plain type="primary">穿透方式：{{ item.cost }}</van-tag>
            </van-col>
            <van-col>
              <van-tag plain type="primary">Nat类型：{{ item.nat_type }}</van-tag>
            </van-col>
          </van-row>
          <van-row :gutter="[20, 20]" justify="space-between">
            <van-col>
              <van-tag plain type="primary">隧道类型：{{ item.tunnel_proto }}</van-tag>
            </van-col>
            <van-col>
              <van-tag plain type="primary">版本：{{ item.version }}</van-tag>
            </van-col>
          </van-row>
          <van-row :gutter="[20, 20]" justify="space-between">
            <van-col>
              <van-tag plain type="primary">延迟：{{ item.lat_ms }}</van-tag>
            </van-col>
            <van-col>
              <van-tag plain type="primary">丢包率：{{ item.loss_rate }}</van-tag>
            </van-col>
          </van-row>
        </van-space>
      </template>
      <template #footer>
        <van-button type="success" size="small" disabled>
          ⬆{{ item.tx_bytes }}
        </van-button>
        <van-button type="danger" size="small" disabled>
          ⬇{{ item.rx_bytes }}
        </van-button>
      </template>
    </van-card>
  </van-cell-group>

</template>

<script setup>
// import { reactive, ref } from 'vue';
import { ETPATH, MODDIR, execCmd, } from './tools'
import { useModuleInfoStore } from './stores/status'
import { useI18n } from './locales'; // 导入所有翻译信息
const { t } = useI18n();
const moduleInfo = useModuleInfoStore();
const ready = ref(false);

const show = ref(false);
const moonId = ref('');
const loading = ref(false);
const activeNames = ref(null);

const items = reactive([])

const startService = () => {
  execCmd(`rm ${ETPATH}/state/disable`).then(v => {
    setTimeout(() => {
      ready.value = true;
      window.location.reload();
    }, 50);
  })
}
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
    execCmd(`sh ${MODDIR}/zerotier.sh status`).then(v => {
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
init()

</script>