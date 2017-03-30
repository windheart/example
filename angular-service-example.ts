
import { Injectable } from "@angular/core";
import { Http, RequestOptions, Headers, Response } from "@angular/http";
import { Observable } from "rxjs/Observable";

import { Address } from "../interfaces/address.model";
import { AppService } from "./app.service";
import { PaymentFlowService } from "./payment-flow.service";
import { PaymentFlow } from "../interfaces/payment-flow.model";


@Injectable()
export class AddressService {
    private flow: PaymentFlow;
    private url: string = `${this.appService.baseUrl}api/rest/v1/checkout/flow/${this.appService.flowId}/addresses`;
    private requestOptions: RequestOptions = new RequestOptions({
        headers: new Headers({'Content-Type': 'application/json'}),
        withCredentials: true
    });

    constructor(
        private http: Http,
        private appService: AppService,
        private flowService: PaymentFlowService
    ) {}

    saveAddress(address: Address) {
        return this.flowService
            .getFlowFromCache()
            .mergeMap((flow: PaymentFlow) => {
                this.flow = flow;
                if (address.id) {
                    return this.http.patch(`${this.url}/${address.id}`, JSON.stringify(address), this.requestOptions)
                } else {
                    return this.http.post(`${this.url}/`, JSON.stringify(address), this.requestOptions)
                }
            })
            .mergeMap((response: Response) => {
                const data = response.json();
                if (address.type == 'billing') {
                    return this.ensurePaymentOptionId(data.paymentOptions);
                }
                if (address.type == 'shipping' && !address.id) {
                    return this.ensureShippingAddressId(data.id);
                }
                return Observable.of(data);
            })
            .do(() => this.appService.addressChanges.emit())
    }

    private ensurePaymentOptionId(paymentOptions: Array<any>) {
        this.flow.paymentOptions = paymentOptions;
        if (this.flow.currentPaymentOption || !this.flow.paymentOptions.length) {
            return Observable.of(this.flow)
        } else {
            this.flow.paymentOptionId = this.flow.paymentOptions[0]['id'];
            return this.flowService.save('paymentOptionId')
        }
    }

    private ensureShippingAddressId(addressId: number) {
        this.flow.shippingAddressId = addressId;
        return this.flowService.save('shippingAddressId', 'isSingleAddress')
    }
}
