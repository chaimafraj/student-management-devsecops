import { Routes } from '@angular/router';
import { Home } from './components/home/home';
import { Search } from './components/search/search';

export const routes: Routes = [
  { path: '', component: Home },
  { path: 'search', component: Search }
];
