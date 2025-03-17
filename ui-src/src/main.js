import { createApp } from 'vue';
import App from './App.vue';
import { createPinia } from 'pinia'
import router from './router'
import { i18n, vantLocales } from './locales'; // 导入所有翻译信息
import 'vant/lib/index.css';

const pinia = createPinia()
//对vant组件进行初始化语言设置
vantLocales(i18n.locale)

createApp(App)
.use(i18n)
.use(router)
.use(pinia)
.mount('#app');
